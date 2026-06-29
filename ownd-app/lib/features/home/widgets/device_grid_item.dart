import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/device.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../../shared/utils/category_utils.dart';
import '../../../shared/config/category_config.dart';
import '../../../shared/config/cost_config.dart';
import '../../../shared/widgets/base_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/utils/category_tree_utils.dart';
import '../../../shared/utils/subscription_utils.dart';
import 'dart:io';
import '../../../shared/widgets/image_preview_dialog.dart';
import '../../add_device/add_device_screen.dart';
import '../home_devices_provider.dart';
import 'package:go_router/go_router.dart';
import 'device_list_item.dart';

class DeviceGridItem extends ConsumerStatefulWidget {
  final Device device;
  final int index;
  final OnDeleteComplete? onDeleteComplete;

  const DeviceGridItem({
    super.key,
    required this.device,
    this.index = 0,
    this.onDeleteComplete,
  });

  @override
  ConsumerState<DeviceGridItem> createState() => _DeviceGridItemState();
}

class _DeviceGridItemState extends ConsumerState<DeviceGridItem>
    with TickerProviderStateMixin {
  late final AnimationController _deleteController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  late final AnimationController _entryController;
  bool _isDeleting = false;
  bool _showSubscriptionUsage = false;

  @override
  void initState() {
    super.initState();
    _deleteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _deleteController, curve: Curves.easeIn));
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _deleteController, curve: Curves.easeOut),
    );
    final shouldAnimateEntry = shouldPlayDeviceEntryAnimation(widget.device.id);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: shouldAnimateEntry ? 0 : 1,
    );
    if (shouldAnimateEntry) {
      final delay = Duration(
        milliseconds: (widget.index > 5 ? 5 : widget.index) * 50,
      );
      if (delay == Duration.zero) {
        _entryController.forward();
      } else {
        Future.delayed(delay, () {
          if (mounted) _entryController.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _deleteController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _startDeleteAnimation() async {
    setState(() => _isDeleting = true);
    await _deleteController.forward();
  }

  IconData _getCategoryIcon(String? categoryName) {
    final item = CategoryConfig.getItem(categoryName);
    return IconUtils.getIconData(item.iconPath);
  }

  Future<void> _navigateToEdit(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddDeviceScreen(device: widget.device),
      ),
    );
    await ref.read(homeDevicesNotifierProvider.notifier).refresh();
  }

  void _navigateToDetail(BuildContext context) {
    context.push('/device/${widget.device.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = CategoryUtils.getCategoryColor(
      widget.device.category.value?.name,
    );
    final categoryIcon = _getCategoryIcon(widget.device.category.value?.name);
    final dailyCost = widget.device.dailyCost;
    final costColor = CostConfig.getCostColor(dailyCost);

    // Handle adaptive color for null categoryColor
    final effectiveCategoryColor = categoryColor ?? theme.colorScheme.onSurface;

    final hasBg =
        widget.device.imagePath != null || widget.device.customIconPath != null;
    final isSubscription = CategoryTreeUtils.isVirtualSubscription(
      widget.device.category.value,
    );
    final subscriptionDueDate = widget.device.subscriptionDueDate;
    final daysUntilDue = subscriptionDueDate == null
        ? null
        : SubscriptionUtils.daysUntilDue(subscriptionDueDate);
    final dueColor = daysUntilDue == null
        ? theme.colorScheme.primary
        : SubscriptionUtils.dueColor(context, daysUntilDue);
    final showUsageMetric = !isSubscription || _showSubscriptionUsage;
    final metricLabel = showUsageMetric ? '使用' : '剩余';
    final metricValue = showUsageMetric
        ? '${widget.device.daysUsed}'
        : daysUntilDue == null
        ? '-'
        : (daysUntilDue < 0 ? 0 : daysUntilDue).toString();
    final cardAccentColor = theme.colorScheme.primary;
    final needsLightText = hasBg || theme.brightness == Brightness.dark;
    final titleColor = needsLightText ? AppColors.snow : AppColors.deepSpace;
    final subtleColor = needsLightText ? AppColors.cloud : AppColors.graphite;
    final accentColor = hasBg ? AppColors.electricViolet : cardAccentColor;
    final dueTextColor = daysUntilDue == null || daysUntilDue > 8
        ? accentColor
        : dueColor;
    final metricColor = showUsageMetric ? accentColor : dueTextColor;
    final detailColor = isSubscription
        ? dueTextColor
        : costColor ?? accentColor;
    final tagColor = accentColor;
    final tagTextColor = needsLightText ? AppColors.snow : tagColor;
    final tagFillColor = hasBg
        ? tagColor.withAlpha(55)
        : tagColor.withAlpha(needsLightText ? 45 : 30);
    final tagBorderColor = tagColor.withAlpha(needsLightText ? 160 : 110);
    const imageTextShadow = [
      Shadow(color: Color(0x800F172A), offset: Offset(0, 1), blurRadius: 1),
    ];
    final textShadow = hasBg ? imageTextShadow : null;

    final childWidget = BaseCard(
      variant: CardVariant.glass,
      backgroundImagePath:
          widget.device.imagePath ?? widget.device.customIconPath,
      onTap: () => _navigateToDetail(context),
      onLongPress: () async {
        final confirmed = await showModalBottomSheet<bool>(
          context: context,
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSubscription)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('编辑'),
                  onTap: () {
                    Navigator.pop(ctx, false);
                    _navigateToEdit(context, ref);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          debugPrint(
            '[DELETE-GRID] Starting delete for device ${widget.device.id}',
          );
          await _startDeleteAnimation();

          try {
            await ref
                .read(deviceRepositoryProvider)
                .deleteDevice(widget.device.id);
            widget.onDeleteComplete?.call(true, null);
          } catch (e) {
            debugPrint('[DELETE-GRID] API error: $e');
            setState(() => _isDeleting = false);
            await _deleteController.reverse();
            widget.onDeleteComplete?.call(false, userErrorMessage(e));
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Hero(
            tag: 'device_icon_${widget.device.id}',
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
              child: widget.device.customIconPath != null
                  ? GestureDetector(
                      onTap: () => ImagePreviewDialog.show(
                        context,
                        widget.device.customIconPath!,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(
                          File(widget.device.customIconPath!),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Icon(categoryIcon, size: 28, color: effectiveCategoryColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.device.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
              shadows: textShadow,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isSubscription
                ? () => setState(
                    () => _showSubscriptionUsage = !_showSubscriptionUsage,
                  )
                : null,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: metricLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      shadows: textShadow,
                    ),
                  ),
                  TextSpan(
                    text: metricValue,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: metricColor,
                      fontSize: 20,
                      shadows: textShadow,
                    ),
                  ),
                  TextSpan(
                    text: '天',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtleColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      shadows: textShadow,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Column(
            children: [
              Text(
                '¥${FormatUtils.formatCurrency(widget.device.price)}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  shadows: textShadow,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isSubscription && subscriptionDueDate != null
                    ? '到期 ${FormatUtils.formatDateShort(subscriptionDueDate)}'
                    : '¥${FormatUtils.formatCurrency(dailyCost)}/天',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: detailColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  shadows: textShadow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 20,
            child: widget.device.tags.isNotEmpty
                ? Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: widget.device.tags
                        .take(3)
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tagFillColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: tagBorderColor,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              '#$tag',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: tagTextColor,
                                fontSize: 9,
                                shadows: textShadow,
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
                child: _buildStatusBadges(widget.device),
              ),
            ),
          ),
        ],
      ),
    );

    if (_isDeleting) {
      return AnimatedBuilder(
        animation: _deleteController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: childWidget,
      );
    }

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Opacity(
          opacity: _entryController.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _entryController.value) * 20),
            child: child,
          ),
        );
      },
      child: childWidget,
    );
  }

  Widget _buildStatusBadges(Device device) {
    List<Widget> badges = [];
    final isSubscription = CategoryTreeUtils.isVirtualSubscription(
      device.category.value,
    );
    if (isSubscription) {
      if (device.status == 'scrap') {
        badges.add(const StatusBadge(text: '已停用', color: Colors.grey));
      } else {
        final now = DateTime.now();
        final nextDate = device.subscriptionDueDate;
        if (nextDate != null) {
          final diff = SubscriptionUtils.daysUntilDue(nextDate, from: now);
          if (device.isAutoRenew) {
            if (diff <= 8 && diff >= 1) {
              badges.add(const StatusBadge(text: '即将到期', color: Colors.orange));
            } else {
              badges.add(const StatusBadge(text: '自动续费', color: Colors.green));
            }
          } else {
            if (diff < 0) {
              badges.add(const StatusBadge(text: '已过期', color: Colors.grey));
            } else if (diff <= 8) {
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
        if (device.status == 'backup') {
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
