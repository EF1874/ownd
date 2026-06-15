import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/error_messages.dart';
import '../services/app_update_service.dart';
import 'app_toast.dart';

void showAppUpdateDialog(
  BuildContext context,
  WidgetRef ref,
  AppUpdateInfo update,
) {
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(update.title ?? '发现新版本 ${update.version}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('版本号: ${update.version}'),
                const SizedBox(height: 4),
                Text('大小: ${_formatBytes(update.apkSizeBytes)}'),
                if (update.forceUpdate) ...[
                  const SizedBox(height: 8),
                  Text(
                    '此版本需要更新后继续使用',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (update.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '更新内容',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...update.releaseNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('- $note'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!update.forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('稍后'),
              ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await startAppUpdateInstall(context, ref, update);
              },
              child: const Text('立即更新'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> startAppUpdateInstall(
  BuildContext context,
  WidgetRef ref,
  AppUpdateInfo update,
) async {
  try {
    final updateService = ref.read(appUpdateServiceProvider);
    final isCached = await updateService.isUpdateCached(update);
    if (!context.mounted) return;

    if (!isCached) {
      AppToast.show(context, '更新包开始下载，可继续使用应用');
    }

    await updateService.downloadAndInstall(update);
    if (!context.mounted) return;

    AppToast.show(context, isCached ? '请按系统提示完成安装' : '下载完成，请按系统提示完成安装');
  } catch (e) {
    if (!context.mounted) return;
    AppToast.show(context, '更新失败: ${userErrorMessage(e)}', isError: true);
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
