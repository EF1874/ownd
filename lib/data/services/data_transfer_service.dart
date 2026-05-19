import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_client.dart';

final dataTransferServiceProvider = Provider<DataTransferService>((ref) {
  return DataTransferService(ref.watch(apiClientProvider));
});

class DataTransferService {
  final ApiClient _apiClient;

  DataTransferService(this._apiClient);

  Future<void> exportData() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await createBackup(fileName: 'user_backup_$timestamp.zip');
  }

  Future<File> createBackup({required String fileName}) async {
    final categories = await _apiClient.get<List<dynamic>>('/categories');
    final devices = await _apiClient.get<List<dynamic>>('/items');

    // Prepare Temp Directory for Staging
    final tempDir = await getTemporaryDirectory();
    final stagingDir = Directory(
      '${tempDir.path}/backup_staging_${DateTime.now().millisecondsSinceEpoch}',
    );
    if (await stagingDir.exists()) {
      await stagingDir.delete(recursive: true);
    }
    await stagingDir.create();

    final devicesData = await Future.wait(
      devices.whereType<Map<String, dynamic>>().map(_exportItem).toList(),
    );

    final data = {
      'version': 3,
      'source': 'ownd-api',
      'timestamp': DateTime.now().toIso8601String(),
      'categories': categories
          .whereType<Map<String, dynamic>>()
          .expand(_flattenCategory)
          .map(_exportCategory)
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

        await _restoreToApi(data);

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

  Future<Map<String, dynamic>> _exportItem(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    final detail = await _apiClient.get<Map<String, dynamic>>('/items/$id');
    final histories = await _apiClient.get<List<dynamic>>(
      '/items/$id/histories',
    );

    return {
      'uuid': id,
      'name': detail['name'],
      'categoryName': (detail['category'] as Map<String, dynamic>?)?['name'],
      'categoryUuid': (detail['category'] as Map<String, dynamic>?)?['id'],
      'price': detail['price'],
      'purchaseDate': detail['purchaseDate'],
      'platform': (detail['platform'] as Map<String, dynamic>?)?['name'],
      'warrantyEndDate': detail['warrantyEndDate'],
      'scrapDate': detail['scrappedDate'],
      'backupDate': detail['backupDate'],
      'imagePath': detail['imagePath'],
      'notes': detail['notes'],
      'tags': detail['tags'] ?? const [],
      'cycleType': _cycleTypeFromApi(detail['currentCycleType'] as String?),
      'currentCycle': detail['currentCycle'],
      'isAutoRenew': detail['isAutoRenew'] ?? false,
      'nextBillingDate': detail['nextBillingDate'],
      'history': histories
          .whereType<Map<String, dynamic>>()
          .map(_exportHistory)
          .toList(),
    };
  }

  Map<String, dynamic> _exportCategory(Map<String, dynamic> category) {
    return {
      'uuid': category['id'],
      'name': category['name'],
      'iconPath': category['icon'] ?? 'MdiIcons.tag',
      'isDefault': category['userId'] == null,
    };
  }

  Map<String, dynamic> _exportHistory(Map<String, dynamic> history) {
    return {
      'type': history['type'] ?? 'RENEWAL',
      'startDate': history['startDate'],
      'endDate': history['endDate'],
      'price': history['price'],
      'cycleType': _cycleTypeFromApi(history['cycleType'] as String?),
      'cycle': history['cycle'],
      'recordDate': history['recordDate'],
      'note': history['note'],
    };
  }

  Future<void> _restoreToApi(Map<String, dynamic> data) async {
    final categoryMap = await _restoreCategories(data['categories']);
    final existingItems = await _apiClient.get<List<dynamic>>('/items');
    final existingIds = existingItems
        .whereType<Map<String, dynamic>>()
        .map((item) => item['id'])
        .whereType<String>()
        .toSet();

    final devices = (data['devices'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    for (final device in devices) {
      final oldUuid = device['uuid'] as String?;
      if (oldUuid != null && existingIds.contains(oldUuid)) {
        continue;
      }

      final created = await _apiClient.post<Map<String, dynamic>>(
        '/items',
        data: _itemPayload(device, categoryMap),
      );
      await _restoreHistories(
        created['id'] as String,
        device['history'] as List<dynamic>? ?? const [],
      );
    }
  }

  Future<Map<String, String>> _restoreCategories(dynamic rawCategories) async {
    final categoryMap = <String, String>{};
    final existing = await _apiClient.get<List<dynamic>>('/categories');

    for (final category in existing.whereType<Map<String, dynamic>>().expand(
      _flattenCategory,
    )) {
      final id = category['id'] as String;
      categoryMap[category['name'] as String] = id;
      categoryMap[id] = id;
    }

    final categories = (rawCategories as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    for (final category in categories) {
      final name = category['name'] as String?;
      if (name == null || name.isEmpty || categoryMap.containsKey(name)) {
        continue;
      }

      final created = await _apiClient.post<Map<String, dynamic>>(
        '/categories',
        data: {'name': name, 'icon': category['iconPath'] ?? 'MdiIcons.tag'},
      );
      final id = created['id'] as String;
      categoryMap[name] = id;
      final oldUuid = category['uuid'];
      if (oldUuid is String) categoryMap[oldUuid] = id;
    }

    return categoryMap;
  }

  Map<String, dynamic> _itemPayload(
    Map<String, dynamic> device,
    Map<String, String> categoryMap,
  ) {
    final categoryKey = device['categoryUuid'] ?? device['categoryName'];
    final cycleType = _cycleTypeToApi(device['cycleType'] as String?);

    return {
      'name': device['name'],
      'price': (device['price'] as num?)?.toDouble() ?? 0,
      'purchaseDate': device['purchaseDate'],
      if (categoryKey is String && categoryMap[categoryKey] != null)
        'categoryId': categoryMap[categoryKey],
      if (device['notes'] != null) 'notes': device['notes'],
      'tags': device['tags'] ?? const [],
      'isVirtual': cycleType != null,
      if (cycleType != null) 'currentCycleType': cycleType,
      if (cycleType != null) 'currentCycle': device['currentCycle'] ?? 1,
      'isAutoRenew': device['isAutoRenew'] ?? false,
      if (device['warrantyEndDate'] != null)
        'warrantyEndDate': device['warrantyEndDate'],
      'isBackup': device['backupDate'] != null,
      if (device['backupDate'] != null) 'backupDate': device['backupDate'],
      'isScrapped': device['scrapDate'] != null,
      if (device['scrapDate'] != null) 'scrappedDate': device['scrapDate'],
    };
  }

  Future<void> _restoreHistories(String itemId, List<dynamic> histories) async {
    for (final rawHistory in histories.whereType<Map<String, dynamic>>()) {
      await _apiClient.post<dynamic>(
        '/items/$itemId/histories',
        data: {
          'type': rawHistory['type'] ?? 'RENEWAL',
          'price': (rawHistory['price'] as num?)?.toDouble() ?? 0,
          if (rawHistory['recordDate'] != null)
            'recordDate': rawHistory['recordDate'],
          if (rawHistory['note'] != null) 'note': rawHistory['note'],
          if (rawHistory['startDate'] != null)
            'startDate': rawHistory['startDate'],
          if (rawHistory['endDate'] != null) 'endDate': rawHistory['endDate'],
          if (_cycleTypeToApi(rawHistory['cycleType'] as String?) != null)
            'cycleType': _cycleTypeToApi(rawHistory['cycleType'] as String?),
          if (rawHistory['cycle'] != null) 'cycle': rawHistory['cycle'],
        },
      );
    }
  }

  Iterable<Map<String, dynamic>> _flattenCategory(Map<String, dynamic> json) {
    return [
      json,
      ...((json['children'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .expand(_flattenCategory),
    ];
  }

  String? _cycleTypeFromApi(String? value) {
    return switch (value) {
      'DAY' => 'daily',
      'WEEK' => 'weekly',
      'MONTH' => 'monthly',
      'QUARTER' => 'quarterly',
      'YEAR' => 'yearly',
      _ => value,
    };
  }

  String? _cycleTypeToApi(String? value) {
    return switch (value) {
      'daily' => 'DAY',
      'weekly' => 'WEEK',
      'monthly' => 'MONTH',
      'quarterly' => 'QUARTER',
      'yearly' => 'YEAR',
      'DAY' || 'WEEK' || 'MONTH' || 'QUARTER' || 'YEAR' => value,
      _ => null,
    };
  }
}
