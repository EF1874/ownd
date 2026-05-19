import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class DeviceGridItem extends ConsumerWidget {
  final Device device;
  final int index;

  const DeviceGridItem({super.key, required this.device, this.index = 0});

  IconData _getCategoryIcon(String? categoryName) {
    final item = CategoryConfig.getItem(categoryName);
    return IconUtils.getIconData(item.iconPath);
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddDeviceScreen(device: device)),
    );
  }

  void _navigateToDetail(BuildContext context) {
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

    final hasBg = device.imagePath != null || device.customIconPath != null;

    return BaseCard(
          variant: CardVariant.glass,
          backgroundImagePath: device.imagePath ?? device.customIconPath,
          onTap: () => _navigateToDetail(context),
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('编辑'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigateToEdit(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      '删除',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref
                          .read(deviceRepositoryProvider)
                          .deleteDevice(device.id);
                    },
                  ),
                ],
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Hero(
                tag: 'device_icon_${device.id}',
                child: Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: effectiveCategoryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: effectiveCategoryColor.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
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
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : Icon(
                          categoryIcon,
                          size: 28,
                          color: effectiveCategoryColor,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                device.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasBg ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    if (CategoryConfig.getMajorCategory(
                          device.category.value?.name,
                        ) ==
                        '虚拟订阅') ...[
                      TextSpan(
                        text: '剩余',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasBg
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: () {
                          if (device.nextBillingDate == null) return '0';
                          final diff =
                              device.nextBillingDate!
                                  .difference(DateTime.now())
                                  .inDays +
                              1;
                          return (diff < 0 ? 0 : diff).toString();
                        }(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: hasBg
                              ? Colors.white
                              : theme.colorScheme.primary, // Cyber Mint
                          fontSize: 20,
                        ),
                      ),
                      TextSpan(
                        text: '天',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasBg
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ] else ...[
                      TextSpan(
                        text: '使用',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasBg
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: '${device.daysUsed}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: hasBg
                              ? Colors.white
                              : theme.colorScheme.primary, // Cyber Mint
                          fontSize: 20,
                        ),
                      ),
                      TextSpan(
                        text: '天',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasBg
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Column(
                children: [
                  Text(
                    '¥${FormatUtils.formatCurrency(device.price)}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: hasBg ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '¥${FormatUtils.formatCurrency(dailyCost)}/天',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: hasBg
                          ? Colors.white
                          : (costColor ?? theme.colorScheme.onSurfaceVariant),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 20,
                child: device.tags.isNotEmpty
                    ? Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: device.tags
                            .take(3)
                            .map(
                              (tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withAlpha(hasBg ? 100 : 50),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: theme.colorScheme.primary.withAlpha(
                                      hasBg ? 200 : 100,
                                    ),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: hasBg
                                        ? Colors.white
                                        : theme.colorScheme.primary,
                                    fontSize: 9,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                      )
                    : null,
              ),
              const Spacer(),
              SizedBox(
                height: 24,
                child: Center(
                  child: Transform.scale(
                    scale: 0.8,
                    child: _buildStatusBadges(device),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms)
        .slideY(
          begin: 0.1,
          delay: (index * 50).ms,
          duration: 300.ms,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildStatusBadges(Device device) {
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

          if (device.isAutoRenew) {
            if (diff <= (device.reminderDays > 0 ? device.reminderDays : 3) &&
                diff >= 0) {
              badges.add(const StatusBadge(text: '即将续费', color: Colors.orange));
            } else {
              badges.add(const StatusBadge(text: '自动续费', color: Colors.green));
            }
          } else {
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
