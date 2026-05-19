import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'data_transfer_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final dataTransferService = ref.watch(dataTransferServiceProvider);
  return BackupService(dataTransferService);
});

class BackupService {
  final DataTransferService _dataTransferService;

  BackupService(this._dataTransferService);

  Future<void> init() async {
    // Initialization handled by DataTransferService implicitly or on demand
  }

  Future<void> createBackup() async {
    try {
      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd');
      final dateStr = formatter.format(now);
      final backupFileName = 'auto_backup_$dateStr.zip';

      await _dataTransferService.createBackup(fileName: backupFileName);
      debugPrint('Backup created: $backupFileName');
    } catch (e) {
      debugPrint('Error creating backup: $e');
    }
  }

  Future<void> cleanupOldBackups() async {
    try {
      // Use the standard backup directory
      String dirPath = await _dataTransferService.getBackupDirectoryPath();
      final backupDir = Directory(dirPath);
      if (!await backupDir.exists()) return;

      final List<FileSystemEntity> files = await backupDir.list().toList();
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      // Matches: auto_backup_YYYY-MM-DD.zip or legacy .json
      final fileNameRegex = RegExp(
        r'auto_backup_(\d{4}-\d{2}-\d{2})\.(zip|json)',
      );

      for (final file in files) {
        if (file is File) {
          final filename = p.basename(file.path);
          final match = fileNameRegex.firstMatch(filename);

          if (match != null) {
            final dateStr = match.group(1)!;
            try {
              final fileDate = DateTime.parse(dateStr);
              // Compare dates (ignoring time)
              final sevenDaysAgoDateOnly = DateTime(
                sevenDaysAgo.year,
                sevenDaysAgo.month,
                sevenDaysAgo.day,
              );
              // Delete if OLDER than 7 days
              if (fileDate.isBefore(sevenDaysAgoDateOnly)) {
                await file.delete();
                debugPrint('Deleted old backup: ${file.path}');
              }
            } catch (e) {
              debugPrint('Error parsing date or deleting file: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up backups: $e');
    }
  }
}
