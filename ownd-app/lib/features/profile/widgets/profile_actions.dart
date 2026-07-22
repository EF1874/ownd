part of '../profile_screen.dart';

extension _ProfileActions on ProfileScreen {
  Future<void> _checkForUpdate(BuildContext context, WidgetRef ref) async {
    try {
      _showSnackBar(context, '正在检查更新...');
      final result = await ref.read(appUpdateServiceProvider).checkForUpdate();
      if (!context.mounted) return;

      if (!result.hasUpdate) {
        _showSnackBar(context, '当前已是最新版本');
        return;
      }

      showAppUpdateDialog(context, ref, result.latest);
    } catch (e) {
      if (context.mounted) {
        final message = userErrorMessage(e, fallback: '更新失败，请稍后重试');
        final isUnavailable =
            e is ApiException &&
            (e.statusCode == 400 || e.statusCode == 404 || e.statusCode == 503);
        final displayMessage = isUnavailable || message == '请求内容有误，请检查后重试'
            ? '检查更新失败，请稍后重试'
            : '检查更新失败: $message';
        _showSnackBar(context, displayMessage);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    AppToast.show(
      context,
      message,
      isError: message.contains('失败') || message.contains('错误'),
    );
  }

  Widget _buildAvatar(BuildContext context, String? avatarPath) {
    const size = 40.0;
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.account_circle_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: avatarPath == null
            ? fallback
            : AppImage(path: avatarPath, width: size, height: size),
      ),
    );
  }

  Future<void> _showNotificationSettingsDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final prefs = ref.read(preferencesServiceProvider);
    var leadDays = prefs.notificationLeadDays;
    var notificationTime = prefs.notificationTime;

    return showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContentContext, setState) {
          final leadDaysTextStyle = Theme.of(
            dialogContentContext,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.normal);

          return AlertDialog(
            title: const Text('提醒设置'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: leadDays,
                  style: leadDaysTextStyle,
                  decoration: const InputDecoration(
                    labelText: '提前提醒',
                    border: OutlineInputBorder(),
                  ),
                  items: PreferencesService.notificationLeadDayOptions
                      .map(
                        (days) => DropdownMenuItem(
                          value: days,
                          child: Text(
                            days == 0 ? '到期当天' : '$days 天',
                            style: leadDaysTextStyle,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => leadDays = value);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('提醒时间'),
                  subtitle: Text('每天 $notificationTime'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final parts = notificationTime.split(':');
                    final time = await showTimePicker(
                      context: dialogContentContext,
                      initialTime: TimeOfDay(
                        hour: int.parse(parts[0]),
                        minute: int.parse(parts[1]),
                      ),
                      builder: (pickerContext, child) {
                        return MediaQuery(
                          data: MediaQuery.of(
                            pickerContext,
                          ).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (time == null) return;
                    final hour = time.hour.toString().padLeft(2, '0');
                    final minute = time.minute.toString().padLeft(2, '0');
                    setState(() => notificationTime = '$hour:$minute');
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(authControllerProvider.notifier)
                        .updatePreferences(
                          notificationLeadDays: leadDays,
                          notificationTime: notificationTime,
                        );
                    await ref
                        .read(subscriptionServiceProvider)
                        .rescheduleAllNotifications();
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    if (context.mounted) _showSnackBar(context, '提醒设置已更新');
                  } catch (e) {
                    if (context.mounted) {
                      _showSnackBar(
                        context,
                        '提醒设置保存失败: ${userErrorMessage(e)}',
                      );
                    }
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImportResultDialog(
    BuildContext context, {
    required int created,
    required int updated,
    required List<String> duplicates,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入完成'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('新增物品: $created 个'),
              const SizedBox(height: 4),
              Text('覆盖更新: $updated 个'),
              if (duplicates.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  '以下物品因重名被合并覆盖:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...duplicates.map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text('• $name'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择主题'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(themeProvider.notifier).setThemeMode(value);
                Navigator.pop(context);
              }
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('跟随系统'),
                  value: ThemeMode.system,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('亮色模式'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('暗色模式'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
