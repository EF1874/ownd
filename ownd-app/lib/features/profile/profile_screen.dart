import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/app_update_prompt.dart';

part 'widgets/profile_actions.dart';

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
                onTap: () => context.push('/profile/account'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildAvatar(context, user.avatarPath),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            user.name ?? user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(authControllerProvider.notifier)
                                .logout();
                          },
                          child: const Text('退出登录'),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
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
                  subtitle: const Text('点击后 1 分钟发送模拟订阅提醒'),
                  onTap: () async {
                    final notificationId =
                        900000 +
                        DateTime.now().millisecondsSinceEpoch.remainder(100000);
                    await ref
                        .read(notificationServiceProvider)
                        .scheduleNotification(
                          id: notificationId,
                          title: '订阅提醒',
                          body: '您的订阅 测试物品 即将到期',
                          scheduledDate: DateTime.now().add(
                            const Duration(minutes: 1),
                          ),
                        );
                    if (context.mounted) {
                      _showSnackBar(context, '已设置，1 分钟后发送提醒');
                    }
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
                              prefs.notificationLeadDays == 0
                                  ? '到期当天 · 每天 ${prefs.notificationTime}'
                                  : '提前 ${prefs.notificationLeadDays} 天 · 每天 ${prefs.notificationTime}',
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
}
