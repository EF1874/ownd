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
  final releaseNoteSections = _parseReleaseNoteSections(update.releaseNotes);

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
                if (releaseNoteSections.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    '更新内容',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  ...releaseNoteSections.map(
                    (section) => _ReleaseNoteSectionView(section: section),
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

List<_ReleaseNoteSection> _parseReleaseNoteSections(List<String> notes) {
  final sections = <_ReleaseNoteSection>[];
  var currentTitle = '';
  var currentItems = <String>[];

  void flush() {
    if (currentItems.isEmpty) {
      currentTitle = '';
      currentItems = <String>[];
      return;
    }

    sections.add(
      _ReleaseNoteSection(title: currentTitle, items: List.of(currentItems)),
    );
    currentTitle = '';
    currentItems = <String>[];
  }

  for (final rawNote in notes) {
    final note = rawNote.trim();
    if (note.isEmpty) {
      continue;
    }

    final heading = _markdownHeading(note);
    if (heading != null) {
      flush();
      currentTitle = heading;
      continue;
    }

    final item = _plainReleaseNoteLine(note);
    if (item.isNotEmpty) {
      currentItems.add(item);
    }
  }

  flush();
  return sections;
}

String? _markdownHeading(String value) {
  final match = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(value);
  if (match == null) {
    return null;
  }

  return match.group(2)?.trim();
}

String _plainReleaseNoteLine(String value) {
  return value
      .replaceFirst(RegExp(r'^[-*]\s+'), '')
      .replaceAll(RegExp(r'[*_`#]'), '')
      .trim();
}

class _ReleaseNoteSection {
  const _ReleaseNoteSection({required this.title, required this.items});

  final String title;
  final List<String> items;
}

class _ReleaseNoteSectionView extends StatelessWidget {
  const _ReleaseNoteSectionView({required this.section});

  final _ReleaseNoteSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.title.isNotEmpty) ...[
            Text(
              section.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
          ],
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
