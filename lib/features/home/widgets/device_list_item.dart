import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/device.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../../shared/utils/category_utils.dart';
import '../../../shared/config/category_config.dart';
import '../../../shared/config/cost_config.dart';
import '../../../shared/widgets/base_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/format_utils.dart';
import 'dart:io';
import '../../../shared/widgets/image_preview_dialog.dart';
import '../../add_device/add_device_screen.dart';
import 'package:go_router/go_router.dart';

class DeviceListItem extends ConsumerWidget {
  final Device device;
  final int index;

  const DeviceListItem({super.key, required this.device, this.index = 0});

  IconData _getCategoryIcon(String? categoryName) {
    final item = CategoryConfig.getItem(categoryName);
    return IconUtils.getIconData(item.iconPath);
  }

  void navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddDeviceScreen(device: device)),
    );
  }

  void navigateToDetail(BuildContext context) {
    context.push('/device/${device.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryColor = CategoryUtils.getCategoryColor(
      device.category.value?.name,
    );
    final categoryIcon = _getCategoryIcon(device.category.value?.name);
    final dailyCost = device.dailyCost;
    final costColor = CostConfig.getCostColor(dailyCost);

    // Handle adaptive color for null categoryColor
    final effectiveCategoryColor = categoryColor ?? theme.colorScheme.onSurface;

    final isSubscription =
        CategoryConfig.getMajorCategory(device.category.value?.name) == '虚拟订阅';

    final hasBg = device.imagePath != null || device.customIconPath != null;

    return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Slidable(
            key: ValueKey(device.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) => navigateToEdit(context),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  icon: Icons.edit,
                  label: '编辑',
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                ),
                SlidableAction(
                  onPressed: (context) {
                    _showDeleteDialog(context, ref);
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: '删除',
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                ),
              ],
            ),
            child: BaseCard(
              variant: CardVariant.glass,
              backgroundImagePath: device.imagePath ?? device.customIconPath,
              onTap: () => navigateToDetail(context),
              child: Row(
                children: [
                  Hero(
                    tag: 'device_icon_${device.id}',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: effectiveCategoryColor.withAlpha(
                          50,
                        ), // 0.2 * 255 for better visibility on glass
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: effectiveCategoryColor.withAlpha(100),
                          width: 1,
                        ),
                      ),
                      child: device.customIconPath != null
                          ? GestureDetector(
                              onTap: () => ImagePreviewDialog.show(
                                context,
                                device.customIconPath!,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.file(
                                  File(device.customIconPath!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : Icon(categoryIcon, color: effectiveCategoryColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: hasBg
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              '¥${FormatUtils.formatCurrency(isSubscription && device.totalAccumulatedPrice > 0 ? device.totalAccumulatedPrice : device.price)}',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: hasBg
                                    ? Colors.white
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '¥${FormatUtils.formatCurrency(device.dailyCost)}/天',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: hasBg
                                    ? Colors.white70
                                    : (costColor ??
                                              theme
                                                  .colorScheme
                                                  .onSurfaceVariant)
                                          .withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 20,
                          child: device.tags.isNotEmpty
                              ? Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: device.tags
                                      .map(
                                        (tag) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .primaryContainer
                                                .withAlpha(hasBg ? 100 : 50),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withAlpha(hasBg ? 200 : 100),
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            '#$tag',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: hasBg
                                                      ? Colors.white
                                                      : theme
                                                            .colorScheme
                                                            .primary,
                                                  fontSize: 10,
                                                ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            if (isSubscription) ...[
                              TextSpan(
                                text: '剩余 ',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: hasBg
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: () {
                                  if (device.nextBillingDate == null) {
                                    return '0';
                                  }
                                  final diff =
                                      device.nextBillingDate!
                                          .difference(DateTime.now())
                                          .inDays +
                                      1;
                                  return (diff < 0 ? 0 : diff).toString();
                                }(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(
                                text: ' 天',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: hasBg
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ] else ...[
                              TextSpan(
                                text: '使用 ',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: hasBg
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: '${device.daysUsed}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                  fontSize: 18,
                                ),
                              ),
                              TextSpan(
                                text: ' 天',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: hasBg
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      buildStatusBadges(device),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms)
        .slideX(
          begin: 0.1,
          delay: (index * 50).ms,
          duration: 300.ms,
          curve: Curves.easeOutQuad,
        );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除?'),
        content: Text('确定要删除 ${device.name} 吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(deviceRepositoryProvider).deleteDevice(device.id);
              Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget buildStatusBadges(Device device) {
    List<Widget> badges = [];

    // Subscription Logic
    final isSubscription =
        CategoryConfig.getMajorCategory(device.category.value?.name) == '虚拟订阅';
    if (isSubscription) {
      if (device.status == 'scrap') {
        badges.add(const StatusBadge(text: '已停用', color: Colors.grey));
      } else {
        final now = DateTime.now();
        final nextDate = device.nextBillingDate;

        if (nextDate != null) {
          final diff = nextDate.difference(now).inDays;
          // Note: difference implies (next - now).
          // If next is tomorrow, diff is 0 or 1 depending on hours.
          // Use .inDays + 1 for "days remaining" inclusive logic or just standard check.
          // Standard check:
          // If nextDate is 2024-12-10, Now is 2024-12-07. Diff is ~3.

          if (device.isAutoRenew) {
            // Auto Renew
            if (diff <= (device.reminderDays > 0 ? device.reminderDays : 3) &&
                diff >= 0) {
              badges.add(const StatusBadge(text: '即将续费', color: Colors.orange));
            } else {
              badges.add(const StatusBadge(text: '自动续费', color: Colors.green));
            }
          } else {
            // Manual
            if (diff < 0) {
              badges.add(const StatusBadge(text: '已过期', color: Colors.grey));
            } else if (diff <=
                (device.reminderDays > 0 ? device.reminderDays : 3)) {
              badges.add(const StatusBadge(text: '即将到期', color: Colors.red));
            }
          }
        } else {
          badges.add(const StatusBadge(text: '无日期', color: Colors.grey));
        }
      }
    } else {
      // Normal Device Logic
      if (device.status == 'scrap') {
        badges.add(const StatusBadge(text: '报废', color: Colors.grey));
      } else {
        if (device.backupDate != null) {
          badges.add(const StatusBadge(text: '备用', color: Colors.blue));
        } else if (device.warrantyEndDate != null &&
            device.warrantyEndDate!.isBefore(DateTime.now())) {
          badges.add(const StatusBadge(text: '过保', color: Colors.orange));
        }
      }
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      children: badges,
    );
  }
}
