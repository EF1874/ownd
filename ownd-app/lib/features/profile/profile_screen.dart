import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:package_info_plus/package_info_plus.dart';
import '../../data/services/data_transfer_service.dart';
import '../../data/services/preferences_service.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/services/subscription_service.dart';
import '../../features/navigation/navigation_provider.dart';
import '../../features/auth/auth_controller.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/platform_repository.dart';
import '../home/home_screen.dart';
import '../home/home_devices_provider.dart';

import '../../shared/widgets/base_card.dart';
import '../../shared/widgets/app_toast.dart';

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
                          _showSnackBar(context, '导出失败: $e');
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
                            final duplicates = (result['duplicates'] as List<dynamic>?)
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
                          _showSnackBar(context, '导入失败: $e');
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
                    await ref
                        .read(notificationServiceProvider)
                        .showNotification(
                          id: 999,
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
                  // We also need to watch preferences_service to get updates on notificationTime
                  // But preferences_service is not a notifier, it's a provider.
                  // Ideally we should make PreferencesService notify listeners or use a StateNotifier.
                  // For now, we will just read it since we don't have a stream.
                  // Wait, if it's not reactive, the UI won't update.
                  // Let's make a small temp provider for it or just use Stateful?
                  // Actually, to keep it simple and consistent with the codebase:
                  // The codebase seems to use SharedPreferences directly in service.
                  // We can wrap the time string in a FutureProvider or just read it.
                  // Let's use a FutureBuilder or ref.watch if we can.
                  // The plan didn't specify refactoring Prefs to be reactive.
                  // I'll assume we can just read it and setState/rebuild when changed.
                  // However, for the UI to reflect the change, we need state.
                  // Let's use a Stateful wrapper or just a simple variable if possible.
                  // Actually, let's look at `themeProvider`. It is reactive.
                  // I'll implement the UI and assume we can refresh it.

                  final prefs = ref.watch(preferencesServiceProvider);
                  // Just for display, we might need a force rebuild if we change it.
                  // Or better, let's create a local state or use `ref.refresh`.

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
                            title: const Text('通知时间'),
                            subtitle: Text('每天 ${prefs.notificationTime} 发送通知'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              final current = prefs.notificationTime;
                              final parts = current.split(':');
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: int.parse(parts[0]),
                                  minute: int.parse(parts[1]),
                                ),
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(
                                      context,
                                    ).copyWith(alwaysUse24HourFormat: true),
                                    child: child!,
                                  );
                                },
                              );

                              if (time != null) {
                                final hour = time.hour.toString().padLeft(
                                  2,
                                  '0',
                                );
                                final minute = time.minute.toString().padLeft(
                                  2,
                                  '0',
                                );
                                final newTime = '$hour:$minute';
                                await prefs.setNotificationTime(newTime);
                                // Reschedule
                                await ref
                                    .read(subscriptionServiceProvider)
                                    .rescheduleAllNotifications();
                                setState(() {}); // Rebuild local widget
                                if (context.mounted) {
                                  _showSnackBar(context, '通知时间已更新');
                                }
                              }
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
                        trailing: Text(version),
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

  void _showSnackBar(BuildContext context, String message) {
    AppToast.show(
      context,
      message,
      isError: message.contains('失败') || message.contains('错误'),
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
