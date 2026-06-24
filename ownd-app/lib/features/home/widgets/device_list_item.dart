import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../../data/models/device.dart';
import '../../../data/repositories/device_repository.dart';
import '../../../core/network/error_messages.dart';
import '../../../shared/utils/icon_utils.dart';
import '../../../shared/utils/category_utils.dart';
import '../../../shared/config/category_config.dart';
import '../../../shared/utils/category_tree_utils.dart';
import '../../../shared/config/cost_config.dart';
import '../../../shared/widgets/base_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/utils/subscription_utils.dart';
import 'dart:io';
import '../../../shared/widgets/image_preview_dialog.dart';
import '../../add_device/add_device_screen.dart';
import '../home_devices_provider.dart';
import 'package:go_router/go_router.dart';

typedef OnDeleteComplete = void Function(bool success, String? error);

class DeviceListItem extends ConsumerStatefulWidget {
  final Device device;
  final int index;
  final OnDeleteComplete? onDeleteComplete;

  const DeviceListItem({
    super.key,
    required this.device,
    this.index = 0,
    this.onDeleteComplete,
  });

  @override
  ConsumerState<DeviceListItem> createState() => _DeviceListItemState();
}

class _DeviceListItemState extends ConsumerState<DeviceListItem>
    with TickerProviderStateMixin {
  late final AnimationController _deleteController;
  late final Animation<double> _heightAnimation;
  late final Animation<double> _opacityAnimation;
  late final AnimationController _entryController;
  bool _isDeleting = false;
  bool _showSubscriptionUsage = false;

  @override
  void initState() {
    super.initState();
    _deleteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _deleteController, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _deleteController, curve: Curves.easeOut),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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

  Future<void> navigateToEdit(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddDeviceScreen(device: widget.device),
      ),
    );
    await ref.read(homeDevicesNotifierProvider.notifier).refresh();
  }

  void navigateToDetail(BuildContext context) {
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
    final effectiveCategoryColor = categoryColor ?? theme.colorScheme.onSurface;
    final isSubscription = CategoryTreeUtils.isVirtualSubscription(
      widget.device.category.value,
    );
    final hasBg =
        widget.device.imagePath != null || widget.device.customIconPath != null;
    final subscriptionDueDate = widget.device.subscriptionDueDate;
    final daysUntilDue = subscriptionDueDate == null
        ? null
        : SubscriptionUtils.daysUntilDue(subscriptionDueDate);
    final dueColor = daysUntilDue == null
        ? theme.colorScheme.primary
        : SubscriptionUtils.dueColor(context, daysUntilDue);
    final showUsageMetric = !isSubscription || _showSubscriptionUsage;
    final metricLabel = showUsageMetric ? '使用 ' : '剩余 ';
    final metricValue = showUsageMetric
        ? '${widget.device.daysUsed}'
        : daysUntilDue == null
        ? '-'
        : (daysUntilDue < 0 ? 0 : daysUntilDue).toString();
    final metricColor = hasBg
        ? Colors.white
        : showUsageMetric
        ? theme.colorScheme.primary
        : dueColor;

    final childWidget = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(widget.device.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            if (!isSubscription)
              SlidableAction(
                onPressed: (context) => navigateToEdit(context, ref),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: '编辑',
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
              ),
            SlidableAction(
              onPressed: (context) => _showDeleteDialog(context, ref),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: '删除',
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(isSubscription ? 12 : 0),
                right: const Radius.circular(12),
              ),
            ),
          ],
        ),
        child: BaseCard(
          variant: CardVariant.glass,
          backgroundImagePath:
              widget.device.imagePath ?? widget.device.customIconPath,
          onTap: () => navigateToDetail(context),
          child: Row(
            children: [
              Hero(
                tag: 'device_icon_${widget.device.id}',
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: effectiveCategoryColor.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: effectiveCategoryColor.withAlpha(100),
                      width: 1,
                    ),
                  ),
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
                      widget.device.name,
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
                          '¥${FormatUtils.formatCurrency(isSubscription && widget.device.totalAccumulatedPrice > 0 ? widget.device.totalAccumulatedPrice : widget.device.price)}',
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
                          isSubscription && subscriptionDueDate != null
                              ? '到期 ${FormatUtils.formatDate(subscriptionDueDate)}'
                              : '¥${FormatUtils.formatCurrency(widget.device.dailyCost)}/天',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: hasBg
                                ? Colors.white70
                                : isSubscription
                                ? dueColor
                                : (costColor ??
                                          theme.colorScheme.onSurfaceVariant)
                                      .withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 20,
                      child: widget.device.tags.isNotEmpty
                          ? Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: widget.device.tags
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
                                        borderRadius: BorderRadius.circular(4),
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
                                                  : theme.colorScheme.primary,
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
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isSubscription
                        ? () => setState(
                            () => _showSubscriptionUsage =
                                !_showSubscriptionUsage,
                          )
                        : null,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: metricLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: hasBg
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(
                            text: metricValue,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: metricColor,
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  buildStatusBadges(widget.device),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (_isDeleting) {
      return AnimatedBuilder(
        animation: _deleteController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _heightAnimation.value,
              child: child,
            ),
          );
        },
        child: childWidget,
      );
    }

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) => Opacity(
        opacity: _entryController.value,
        child: Transform.translate(
          offset: Offset((1 - _entryController.value) * 30, 0),
          child: child,
        ),
      ),
      child: childWidget,
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除?'),
        content: Text('确定要删除 ${widget.device.name} 吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      debugPrint('[DELETE] Starting delete for device ${widget.device.id}');
      await _startDeleteAnimation();

      try {
        await ref.read(deviceRepositoryProvider).deleteDevice(widget.device.id);
        widget.onDeleteComplete?.call(true, null);
      } catch (e) {
        debugPrint('[DELETE] API error: $e');
        setState(() => _isDeleting = false);
        await _deleteController.reverse();
        widget.onDeleteComplete?.call(false, userErrorMessage(e));
      }
    }
  }

  Widget buildStatusBadges(Device device) {
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
