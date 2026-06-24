import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_client.dart';
import '../../core/network/error_messages.dart';

final dataTransferServiceProvider = Provider<DataTransferService>((ref) {
  return DataTransferService(ref.watch(apiClientProvider));
});

class DataTransferService {
  final ApiClient _apiClient;
  static const _channel = MethodChannel('com.antigravity.ownd/saf');

  DataTransferService(this._apiClient);

  Future<void> exportData() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await createBackup(fileName: 'user_backup_$timestamp.zip');
  }

  Future<String> createBackup({required String fileName}) async {
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

    // Cleanup staging
    await stagingDir.delete(recursive: true);

    // Save to user-chosen directory via SAF
    final zipBytes = await File(zipPath).readAsBytes();
    await File(zipPath).delete();

    final savedUri = await _saveViaSaf(fileName, zipBytes);
    return savedUri;
  }

  Future<String> _saveViaSaf(String fileName, List<int> bytes) async {
    // Check if user has already chosen a backup directory
    String? directoryUri = await _channel.invokeMethod<String>(
      'getSavedDirectoryUri',
    );

    // If not set, prompt user to pick a directory
    directoryUri ??= await _channel.invokeMethod<String>('pickDirectory');

    if (directoryUri == null) {
      throw '未选择保存位置';
    }

    final base64Data = base64Encode(bytes);
    final result = await _channel
        .invokeMethod<String>('createFileInDirectory', {
          'directoryUri': directoryUri,
          'fileName': fileName,
          'mimeType': 'application/zip',
          'data': base64Data,
        });

    if (result == null) {
      // Directory may have been deleted, clear and retry once
      await _channel.invokeMethod('clearSavedDirectoryUri');
      final newDir = await _channel.invokeMethod<String>('pickDirectory');
      if (newDir == null) throw '未选择保存位置';

      final retryResult = await _channel
          .invokeMethod<String>('createFileInDirectory', {
            'directoryUri': newDir,
            'fileName': fileName,
            'mimeType': 'application/zip',
            'data': base64Data,
          });
      if (retryResult == null) throw '文件保存失败';
      return retryResult;
    }

    return result;
  }

  Future<Map<String, dynamic>?> importData() async {
    try {
      // Use SAF to pick a file (bypasses scoped storage restrictions)
      final base64Data = await _channel.invokeMethod<String>('openFile');
      if (base64Data == null) return null; // User cancelled

      final bytes = base64Decode(base64Data);

      Map<String, dynamic> data;
      String? stagingPath;

      // Try to detect if it's a ZIP file by checking magic bytes
      final isZip =
          bytes.length >= 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4B &&
          bytes[2] == 0x03 &&
          bytes[3] == 0x04;

      if (isZip) {
        final archive = ZipDecoder().decodeBytes(bytes);

        final tempDir = await getTemporaryDirectory();
        stagingPath =
            '${tempDir.path}/import_staging_${DateTime.now().millisecondsSinceEpoch}';
        await Directory(stagingPath).create();

        for (final file in archive) {
          if (file.isFile) {
            final data = file.content as List<int>;
            File('$stagingPath/${file.name}')
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          } else {
            await Directory(
              '$stagingPath/${file.name}',
            ).create(recursive: true);
          }
        }

        // Find backup.json
        final dir = Directory(stagingPath);
        File? jsonFile;
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.json')) {
            jsonFile = entity;
            break;
          }
        }

        if (jsonFile == null) {
          throw '无效的备份文件：ZIP 中未找到 JSON';
        }

        data = jsonDecode(await jsonFile.readAsString());
      } else {
        // Legacy JSON import
        data = jsonDecode(utf8.decode(bytes));
      }

      final result = await _restoreToApi(data);

      // Cleanup staging
      if (stagingPath != null) {
        await Directory(stagingPath).delete(recursive: true);
      }

      return result;
    } catch (e) {
      debugPrint('Import failed: $e');
      throw Exception(userErrorMessage(e, fallback: '导入失败，请稍后重试'));
    }
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
      'renewalPrice': detail['renewalPrice'],
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
      'cycleMode': detail['currentCycleMode'] ?? 'CALENDAR',
      'cycleDays': detail['currentCycleDays'],
      'isAutoRenew': detail['isAutoRenew'] ?? false,
      'nextBillingDate': detail['nextBillingDate'],
      'hasReminder': detail['hasReminder'] ?? false,
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
      'cycleMode': history['cycleMode'] ?? 'CALENDAR',
      'cycleDays': history['cycleDays'],
      'recordDate': history['recordDate'],
      'note': history['note'],
      'isAutoRenew':
          history['isAutoRenew'] == true ||
          (history['note'] is String &&
              (history['note'] as String).startsWith('自动续费')),
    };
  }

  Future<Map<String, dynamic>?> _restoreToApi(Map<String, dynamic> data) async {
    final result = await _apiClient.post<dynamic>('/items/import', data: data);
    if (result is Map<String, dynamic>) {
      return result;
    }
    return null;
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
      'HALF_YEAR' => 'halfYearly',
      'YEAR' => 'yearly',
      _ => value,
    };
  }

  Future<String> getBackupDirectoryPath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/DeviceManager';
    }
    final downloadDir = await getDownloadsDirectory();
    final baseDir = downloadDir ?? await getApplicationDocumentsDirectory();
    return '${baseDir.path}/DeviceManager';
  }
}
