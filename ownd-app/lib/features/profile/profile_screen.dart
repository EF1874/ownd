import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:package_info_plus/package_info_plus.dart';
import '../../data/services/data_transfer_service.dart';
import '../../data/services/preferences_service.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/subscription_service.dart';
import '../../shared/services/app_update_service.dart';
import '../../features/navigation/navigation_provider.dart';
import '../../features/auth/auth_controller.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/error_messages.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/platform_repository.dart';
import '../home/home_screen.dart';
import '../home/home_devices_provider.dart';

import '../../shared/widgets/base_card.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/app_update_prompt.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transferService = ref.watch(dataTransferServiceProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.asData?.value?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('个人中心')),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.reverse) {
            ref.read(bottomNavBarVisibleProvider.notifier).state = false;
          } else if (notification.direction == ScrollDirection.forward) {
            ref.read(bottomNavBarVisibleProvider.notifier).state = true;
          }
          return true;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (user != null) ...[
              BaseCard(
                child: ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: Text(user.name ?? user.email),
                  subtitle: Text(user.email),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                    },
                    child: const Text('退出登录'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            _buildSectionHeader(context, '数据管理'),
            const SizedBox(height: 8),
            BaseCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('导出数据'),
                    subtitle: const Text('备份数据到选择的文件夹'),
                    onTap: () async {
                      try {
                        _showSnackBar(context, '正在导出...');
                        final timestamp = DateTime.now().millisecondsSinceEpoch;
                        await transferService.createBackup(
                          fileName: 'user_backup_$timestamp.zip',
                        );
                        if (context.mounted) {
                          _showSnackBar(context, '导出成功');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          _showSnackBar(
                            context,
                            '导出失败: ${userErrorMessage(e)}',
                          );
                        }
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.upload),
                    title: const Text('导入数据'),
                    subtitle: const Text('从备份文件恢复数据'),
                    onTap: () async {
                      try {
                        _showSnackBar(context, '请选择备份文件...');

                        final result = await transferService.importData();

                        ref.invalidate(categoryTreeProvider);
                        ref.invalidate(platformsProvider);
                        ref.invalidate(deviceListProvider);
                        ref.invalidate(homeDevicesNotifierProvider);

                        if (context.mounted) {
                          if (result != null) {
                            final created = result['createdCount'] ?? 0;
                            final updated = result['updatedCount'] ?? 0;
                            final duplicates =
                                (result['duplicates'] as List<dynamic>?)
                                    ?.cast<String>() ??
                                [];
                            _showImportResultDialog(
                              context,
                              created: created as int,
                              updated: updated as int,
                              duplicates: duplicates,
                            );
                          } else {
                            _showSnackBar(context, '导入成功');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          _showSnackBar(
                            context,
                            '导入失败: ${userErrorMessage(e)}',
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              _buildSectionHeader(context, '功能测试'),
              const SizedBox(height: 8),
              BaseCard(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('测试通知功能'),
                  subtitle: const Text('立即发送一条测试通知'),
                  onTap: () async {
                    final notificationId =
                        900000 +
                        DateTime.now().millisecondsSinceEpoch.remainder(100000);
                    await ref
                        .read(notificationServiceProvider)
                        .showNotification(
                          id: notificationId,
                          title: '测试通知',
                          body: '这是一条主动触发的测试通知！',
                        );
                    if (context.mounted) _showSnackBar(context, '通知已发送');
                  },
                ),
              ),
            ],

            const SizedBox(height: 24),
            _buildSectionHeader(context, '应用设置'),
            const SizedBox(height: 8),
            BaseCard(
              child: Consumer(
                builder: (context, ref, child) {
                  final currentMode = ref.watch(themeProvider);
                  final prefs = ref.watch(preferencesServiceProvider);

                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.brightness_6),
                        title: const Text('主题设置'),
                        subtitle: Text(
                          currentMode == ThemeMode.system
                              ? '跟随系统'
                              : currentMode == ThemeMode.light
                              ? '亮色模式'
                              : '暗色模式',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _showThemeDialog(context, ref, currentMode),
                      ),
                      const Divider(),
                      StatefulBuilder(
                        builder: (context, setState) {
                          return ListTile(
                            leading: const Icon(Icons.access_time),
                            title: const Text('提醒设置'),
                            subtitle: Text(
                              '提前 ${prefs.notificationLeadDays} 天 · 每天 ${prefs.notificationTime}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await _showNotificationSettingsDialog(
                                context,
                                ref,
                              );
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(context, '关于'),
            const SizedBox(height: 8),
            BaseCard(
              child: Column(
                children: [
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '...';
                      return ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('版本'),
                        subtitle: const Text('点击检查更新'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(version),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => _checkForUpdate(context, ref),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          return AlertDialog(
            title: const Text('提醒设置'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: leadDays,
                  decoration: const InputDecoration(
                    labelText: '提前提醒',
                    border: OutlineInputBorder(),
                  ),
                  items: PreferencesService.notificationLeadDayOptions
                      .map(
                        (days) => DropdownMenuItem(
                          value: days,
                          child: Text('$days 天'),
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
