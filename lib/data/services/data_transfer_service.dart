import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/device.dart';
import 'database_service.dart';

final dataTransferServiceProvider = Provider<DataTransferService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return DataTransferService(dbService.isar);
});

class DataTransferService {
  final Isar _isar;

  DataTransferService(this._isar);

  Future<void> exportData() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await createBackup(fileName: 'user_backup_$timestamp.zip');
  }

  Future<File> createBackup({required String fileName}) async {
    // 1. Ensure all data has UUIDs (Migration)
    await _isar.writeTxn(() async {
      final categories = await _isar.categorys.where().findAll();
      for (final category in categories) {
        if (category.uuid == null) {
          category.uuid = const Uuid().v4();
          await _isar.categorys.put(category);
        }
      }
    });

    final devices = await _isar.devices.where().findAll();
    final categories = await _isar.categorys.where().findAll();

    // Prepare Temp Directory for Staging
    final tempDir = await getTemporaryDirectory();
    final stagingDir = Directory(
      '${tempDir.path}/backup_staging_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (await stagingDir.exists()) {
      await stagingDir.delete(recursive: true);
    }
    await stagingDir.create();

    final imagesDir = Directory('${stagingDir.path}/images');
    await imagesDir.create();

    // Process Devices and Copy Images
    final devicesData = await Future.wait(
      devices.map((e) async {
        String? relativeIconPath;
        if (e.customIconPath != null) {
          final originalFile = File(e.customIconPath!);
          if (await originalFile.exists()) {
            final fileName = p.basename(e.customIconPath!);
            // Copy to staging images folder
            // Use UUID in filename to avoid collisions if multiple devices use "image.jpg"
            final newFileName = '${e.uuid}_$fileName';
            await originalFile.copy('${imagesDir.path}/$newFileName');
            relativeIconPath = 'images/$newFileName';
          }
        }

        return {
          'uuid': e.uuid,
          'name': e.name,
          'categoryName': e.category.value?.name,
          'price': e.price,
          'purchaseDate': e.purchaseDate.toIso8601String(),
          'platform': e.platform,
          'warrantyEndDate': e.warrantyEndDate?.toIso8601String(),
          'scrapDate': e.scrapDate?.toIso8601String(),
          'backupDate': e.backupDate?.toIso8601String(),
          'customIconPath': relativeIconPath, // Store relative path in ZIP
          // Subscription Fields
          'cycleType': e.cycleType?.name,
          'isAutoRenew': e.isAutoRenew,
          'nextBillingDate': e.nextBillingDate?.toIso8601String(),
          'reminderDays': e.reminderDays,
          'hasReminder': e.hasReminder,
          'firstPeriodPrice': e.firstPeriodPrice,
          'periodPrice': e.periodPrice,
          'totalAccumulatedPrice': e.totalAccumulatedPrice,
          'history': e.history
              .map(
                (h) => {
                  'startDate': h.startDate?.toIso8601String(),
                  'endDate': h.endDate?.toIso8601String(),
                  'price': h.price,
                  'cycleType': h.cycleType.name,
                  'isAutoRenew': h.isAutoRenew,
                  'recordDate': h.recordDate?.toIso8601String(),
                  'note': h.note,
                },
              )
              .toList(),
        };
      }).toList(),
    );

    final data = {
      'version': 2, // Bump version to 2 for ZIP format
      'timestamp': DateTime.now().toIso8601String(),
      'categories': categories
          .map(
            (e) => {
              'uuid': e.uuid,
              'name': e.name,
              'iconPath': e.iconPath,
              'isDefault': e.isDefault,
            },
          )
          .toList(),
      'devices': devicesData,
    };

    final jsonString = jsonEncode(data);
    final jsonFile = File('${stagingDir.path}/backup.json');
    await jsonFile.writeAsString(jsonString);

    // Create ZIP
    final zipFileEncoder = ZipFileEncoder();
    final zipPath = '${tempDir.path}/$fileName';
    zipFileEncoder.create(zipPath);
    await zipFileEncoder.addDirectory(stagingDir);
    await zipFileEncoder.close();

    // Move ZIP to Output Directory
    Directory? outputDir;
    if (Platform.isAndroid) {
      outputDir = Directory('/storage/emulated/0/Download/Ownd');
    } else {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir != null) {
        outputDir = Directory('${downloadDir.path}/Ownd');
      }
    }

    if (outputDir == null) {
      final docDir = await getApplicationDocumentsDirectory();
      outputDir = Directory('${docDir.path}/Ownd');
    }

    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final finalZipFile = File(p.join(outputDir.path, fileName));
    await File(zipPath).copy(finalZipFile.path);

    // Cleanup
    await stagingDir.delete(recursive: true);
    await File(zipPath).delete();

    return finalZipFile;
  }

  Future<void> importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);

        Map<String, dynamic> data;
        String? stagingPath;

        // Detect if ZIP or JSON (Legacy support)
        if (path.toLowerCase().endsWith('.zip')) {
          final bytes = await file.readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);

          final tempDir = await getTemporaryDirectory();
          stagingPath =
              '${tempDir.path}/import_staging_${DateTime.now().millisecondsSinceEpoch}';
          await Directory(stagingPath).create();

          // Extract all files
          for (final file in archive) {
            final filename = file.name;
            if (file.isFile) {
              final data = file.content as List<int>;
              File('$stagingPath/$filename')
                ..createSync(recursive: true)
                ..writeAsBytesSync(data);
            } else {
              await Directory('$stagingPath/$filename').create(recursive: true);
            }
          }

          // Find backup.json
          // The structure inside zip might be "backup_staging_xxx/backup.json" or just "backup.json"
          // depending on how zipEncoder.addDirectory works (it usually includes the dir name).
          // Let's find any .json file recursively or check known structure.
          final dir = Directory(stagingPath);
          File? jsonFile;
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File && entity.path.endsWith('.json')) {
              jsonFile = entity;
              break;
            }
          }

          if (jsonFile == null) {
            throw 'Invalid backup file: No JSON found in ZIP';
          }

          data = jsonDecode(await jsonFile.readAsString());
        } else {
          // Legacy JSON import
          final jsonString = await file.readAsString();
          data = jsonDecode(jsonString);
        }

        await _isar.writeTxn(() async {
          // 1. Restore Categories
          final categoryMap = <String, Category>{};
          if (data['categories'] != null) {
            final categoriesList = data['categories'] as List;
            for (final catData in categoriesList) {
              final uuid = catData['uuid'];
              final name = catData['name'];

              Category? category;
              if (uuid != null) {
                category = await _isar.categorys
                    .filter()
                    .uuidEqualTo(uuid)
                    .findFirst();
              }
              category ??= await _isar.categorys
                  .filter()
                  .nameEqualTo(name)
                  .findFirst();

              if (category == null) {
                category = Category()
                  ..uuid = uuid ?? const Uuid().v4()
                  ..name = name
                  ..iconPath = catData['iconPath']
                  ..isDefault = catData['isDefault'] ?? false;
                await _isar.categorys.put(category);
              } else {
                if (category.uuid == null && uuid != null) {
                  category.uuid = uuid;
                  await _isar.categorys.put(category);
                }
              }
              categoryMap[name] = category;
              if (uuid != null) categoryMap[uuid] = category;
            }
          }

          // 2. Restore Devices
          if (data['devices'] != null) {
            final devicesList = data['devices'] as List;
            for (final devData in devicesList) {
              final uuid = devData['uuid'];

              if (uuid != null) {
                // Check if device exists. If so, update it or skip?
                // Usually restore implies overwriting or adding missing.
                // Let's skip existing to prevent duplicates, OR update if it's the same device.
                // For simplicity, skip if UUID exists.
                final existing = await _isar.devices
                    .filter()
                    .uuidEqualTo(uuid)
                    .findFirst();
                if (existing != null) {
                  continue;
                }
              }

              final device = Device()
                ..uuid = uuid ?? const Uuid().v4()
                ..name = devData['name']
                ..price = (devData['price'] as num).toDouble()
                ..purchaseDate = DateTime.parse(devData['purchaseDate'])
                ..platform = devData['platform']
                ..warrantyEndDate = devData['warrantyEndDate'] != null
                    ? DateTime.parse(devData['warrantyEndDate'])
                    : null
                ..scrapDate = devData['scrapDate'] != null
                    ? DateTime.parse(devData['scrapDate'])
                    : null
                ..backupDate = devData['backupDate'] != null
                    ? DateTime.parse(devData['backupDate'])
                    : null
                // Subscription Fields
                ..cycleType = devData['cycleType'] != null
                    ? CycleType.values.firstWhere(
                        (e) => e.name == devData['cycleType'],
                        orElse: () => CycleType.monthly,
                      )
                    : null
                ..isAutoRenew = devData['isAutoRenew'] ?? false
                ..nextBillingDate = devData['nextBillingDate'] != null
                    ? DateTime.parse(devData['nextBillingDate'])
                    : null
                ..reminderDays = devData['reminderDays'] ?? 1
                ..hasReminder = devData['hasReminder'] ?? false
                ..firstPeriodPrice = devData['firstPeriodPrice'] != null
                    ? (devData['firstPeriodPrice'] as num).toDouble()
                    : null
                ..periodPrice = devData['periodPrice'] != null
                    ? (devData['periodPrice'] as num).toDouble()
                    : null
                ..totalAccumulatedPrice =
                    (devData['totalAccumulatedPrice'] ?? 0.0).toDouble();

              // Restore Custom Icon (ZIP or Legacy)
              if (devData['customIconPath'] != null) {
                String path = devData['customIconPath'];
                if (stagingPath != null && path.startsWith('images/')) {
                  // It's a relative path from ZIP
                  // Note: The zip might have extracted to "staging/backup_staging_xxx/images/..."
                  // or "staging/images/..." depending on zip structure.
                  // We need to find the file in staging dir.

                  // Construct potential full path in staging
                  // Assuming flat unzip or preserving structure.
                  // Let's search for the image file by name in the staging dir if strict path fails.
                  final fileName = p.basename(path);

                  File? sourceFile;
                  final stagingDirectory = Directory(stagingPath);
                  await for (final entity in stagingDirectory.list(
                    recursive: true,
                  )) {
                    if (entity is File && p.basename(entity.path) == fileName) {
                      sourceFile = entity;
                      break;
                    }
                  }

                  if (sourceFile != null) {
                    final appDir = await getApplicationDocumentsDirectory();
                    final appDocsImagesDir = Directory(
                      '${appDir.path}/imported_icons',
                    ); // Separate folder or root?
                    if (!await appDocsImagesDir.exists()) {
                      await appDocsImagesDir.create();
                    }
                    final newPath = '${appDocsImagesDir.path}/$fileName';
                    await sourceFile.copy(newPath);
                    device.customIconPath = newPath;
                  }
                } else {
                  // Legacy: absolute path or Base64 (if we kept it, but we removed it).
                  // Base64 field check (backward compat for the version we just wrote but didn't release? No, user won't have it).
                  // If it's an old absolute path, check if it exists (local restore).
                  if (await File(path).exists()) {
                    device.customIconPath = path;
                  }
                }
              }

              // History
              if (devData['history'] != null) {
                final historyList = (devData['history'] as List).map((h) {
                  final hist = SubscriptionHistory();
                  hist.startDate = h['startDate'] != null
                      ? DateTime.parse(h['startDate'])
                      : null;
                  hist.endDate = h['endDate'] != null
                      ? DateTime.parse(h['endDate'])
                      : null;
                  hist.price = (h['price'] as num).toDouble();
                  hist.isAutoRenew = h['isAutoRenew'] ?? false;
                  hist.recordDate = h['recordDate'] != null
                      ? DateTime.parse(h['recordDate'])
                      : null;
                  hist.note = h['note'];
                  if (h['cycleType'] != null) {
                    try {
                      hist.cycleType = CycleType.values.byName(h['cycleType']);
                    } catch (_) {}
                  }
                  return hist;
                }).toList();
                device.history = historyList;
              }

              await _isar.devices.put(device);

              final catName = devData['categoryName'];
              if (catName != null && categoryMap.containsKey(catName)) {
                device.category.value = categoryMap[catName];
                await device.category.save();
              }
            }
          }
        });

        // Cleanup staging
        if (stagingPath != null) {
          await Directory(stagingPath).delete(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Import failed: $e');
      throw 'Import failed: $e';
    }
  }

  Future<String> getBackupDirectoryPath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/Ownd';
    }
    final downloadDir = await getDownloadsDirectory();
    final baseDir = downloadDir ?? await getApplicationDocumentsDirectory();
    return '${baseDir.path}/Ownd';
  }
}
