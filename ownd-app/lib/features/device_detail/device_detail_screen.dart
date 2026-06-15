import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add for SystemUiOverlayStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/device.dart';
import '../../data/repositories/device_repository.dart';
import '../../core/network/error_messages.dart';
import '../../shared/config/category_config.dart';
import '../../shared/utils/category_utils.dart';
import '../../shared/utils/icon_utils.dart';
import '../../shared/utils/format_utils.dart';
import '../../shared/utils/category_tree_utils.dart';
import '../../shared/utils/subscription_utils.dart';
import '../../shared/config/cost_config.dart';
import '../../shared/services/subscription_service.dart';
import '../../shared/widgets/base_card.dart';
import '../../shared/widgets/app_toast.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_devices_provider.dart';
import '../add_device/add_device_screen.dart';
import 'widgets/renew_dialog.dart';

final deviceDetailProvider = FutureProvider.family<Device, int>((ref, id) {
  return ref.read(deviceRepositoryProvider).getDevice(id);
});

class DeviceDetailScreen extends ConsumerWidget {
  final int id;
  const DeviceDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDevice = ref.watch(deviceDetailProvider(id));
    final theme = Theme.of(context);

    return asyncDevice.when(
      data: (device) {
        final isSub = CategoryTreeUtils.isVirtualSubscription(
          device.category.value,
        );

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildHeaderBackground(device, theme),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              theme.scaffoldBackgroundColor,
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                      // Status bar safety gradient
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black54, Colors.transparent],
                            stops: [0.0, 0.4],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddDeviceScreen(device: device),
                        ),
                      );
                      if (!context.mounted) return;
                      ref.invalidate(deviceDetailProvider(id));
                      await ref
                          .read(homeDevicesNotifierProvider.notifier)
                          .silentRefresh();
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Header
                      Text(
                        device.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTagsSection(device, theme),
                      const SizedBox(height: 16),
                      _buildCostAnalysisCard(device, theme),
                      const SizedBox(height: 16),
                      if (isSub) ...[
                        _buildSubscriptionInfoCard(device, theme, context, ref),
                        const SizedBox(height: 16),
                        _buildSubscriptionHistory(device, theme),
                      ] else
                        _buildBasicInfoCard(device, theme),
                      if (device.notes != null && device.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildNotesSection(device.notes!, theme),
                      ],
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(
        body: Center(child: Text(userErrorMessage(e, fallback: '加载失败，请稍后重试'))),
      ),
    );
  }

  Widget _buildHeaderBackground(Device device, ThemeData theme) {
    if (device.imagePath != null) {
      return Hero(
        tag: 'device_image_${device.id}',
        child: Image.file(File(device.imagePath!), fit: BoxFit.cover),
      );
    }

    final color =
        CategoryUtils.getCategoryColor(device.category.value?.name) ??
        theme.colorScheme.primary;
    final item = CategoryConfig.getItem(device.category.value?.name);
    final iconData = IconUtils.getIconData(item.iconPath);

    return Hero(
      tag: 'device_icon_${device.id}',
      child: Container(
        color: color.withValues(alpha: 0.2),
        child: Center(
          child: device.customIconPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(device.customIconPath!),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              : Icon(iconData, size: 80, color: color),
        ),
      ),
    );
  }

  Widget _buildCostAnalysisCard(Device device, ThemeData theme) {
    final dailyCostStr = FormatUtils.formatCurrency(device.dailyCost);
    final isSub = CategoryTreeUtils.isVirtualSubscription(
      device.category.value,
    );
    final totalCostStr = FormatUtils.formatCurrency(
      isSub ? _subscriptionTotal(device) : device.totalAccumulatedPrice,
    );
    final costColor = CostConfig.getCostColor(device.dailyCost);

    return BaseCard(
      variant: CardVariant.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '成本分析',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CostMetric(
                label: '购入价格',
                prefix: '¥',
                number: FormatUtils.formatCurrency(device.price),
                valueColor: theme.colorScheme.primary,
              ),
              _CostMetric(
                label: isSub ? '累计支出' : '日均成本',
                prefix: '¥',
                number: isSub ? totalCostStr : dailyCostStr,
                valueColor: costColor ?? theme.colorScheme.error,
              ),
            ],
          ),
          if (!isSub) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InlineNumberText(
                  prefix: '已使用 ',
                  number: '${device.daysUsed}',
                  suffix: ' 天',
                  color: AppColors.ash,
                  numberStyle: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _InlineNumberText(
                  prefix: '月均 ¥',
                  number: FormatUtils.formatCurrency(device.dailyCost * 30),
                  color: AppColors.ash,
                  numberStyle: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(Device device, ThemeData theme) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return BaseCard(
      variant: CardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '基础信息',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: '分类', value: device.category.value?.name ?? '未分类'),
          const Divider(height: 24),
          _InfoRow(
            label: '购入日期',
            value: dateFormat.format(device.purchaseDate),
          ),
          if ((device.platform ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            _InfoRow(label: '平台/渠道', value: device.platform!),
          ],
          if (device.warrantyEndDate != null) ...[
            const Divider(height: 24),
            _InfoRow(
              label: '保修截止',
              value: dateFormat.format(device.warrantyEndDate!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionInfoCard(
    Device device,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
  ) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final periods = _subscriptionPeriods(device);
    final currentPeriod = _currentPeriodNumber(periods, device);
    final totalPeriods = periods.length;
    final dueDate = device.subscriptionDueDate;
    final daysUntilDue = dueDate == null
        ? null
        : SubscriptionUtils.daysUntilDue(dueDate);
    final dueColor = daysUntilDue == null
        ? theme.colorScheme.primary
        : SubscriptionUtils.dueColor(context, daysUntilDue);
    return BaseCard(
      variant: CardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event_repeat,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '订阅信息',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _CostMetric(
                label: dueDate == null ? '到期状态' : '剩余天数',
                prefix: daysUntilDue != null && daysUntilDue < 0
                    ? '已过期 '
                    : null,
                number: daysUntilDue == null
                    ? '--'
                    : daysUntilDue < 0
                    ? '${-daysUntilDue}'
                    : '$daysUntilDue',
                suffix: daysUntilDue == null ? null : ' 天',
                valueColor: dueColor,
              ),
              _CostMetric(
                label: '当前期数',
                prefix: currentPeriod == 0 ? null : '第',
                number: currentPeriod == 0 ? '--' : '$currentPeriod',
                suffix: currentPeriod == 0 ? null : ' 期',
                valueColor: theme.colorScheme.primary,
              ),
              _CostMetric(
                label: '总计期数',
                prefix: '共 ',
                number: '$totalPeriods',
                suffix: ' 期',
                valueColor: theme.colorScheme.primary,
              ),
            ],
          ),
          const Divider(height: 24),
          _InfoRow(label: '分类', value: device.category.value?.name ?? '未分类'),
          if ((device.platform ?? '').isNotEmpty) ...[
            const Divider(height: 24),
            _InfoRow(label: '平台/渠道', value: device.platform!),
          ],
          const Divider(height: 24),
          _InfoRow(
            label: device.isAutoRenew ? '到期/续费时间' : '到期时间',
            value: dueDate == null ? '未设置' : dateFormat.format(dueDate),
          ),
          const Divider(height: 24),
          _InfoRow(
            label: '当前订阅模式',
            value: SubscriptionUtils.cycleLabel(device.cycleType),
          ),
          const Divider(height: 24),
          _InfoRow(label: '续费方式', value: device.isAutoRenew ? '自动续费' : '手动续费'),
          const Divider(height: 24),
          _SwitchInfoRow(
            label: '到期提醒',
            subtitle: device.hasReminder
                ? '到期前 ${device.reminderDays} 天提醒'
                : '不提醒',
            value: device.hasReminder,
            onChanged: (enabled) =>
                _toggleReminder(context, ref, device, enabled),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRenewDialog(context, ref, device),
              icon: const Icon(Icons.event_repeat),
              label: const Text('手动续费'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRenewDialog(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    if (device.cycleType == null || device.cycleType == CycleType.oneTime) {
      AppToast.show(context, '当前订阅无法续费', isError: true);
      return;
    }

    final today = SubscriptionUtils.dateOnly(DateTime.now());
    final dueDate = device.subscriptionDueDate;
    final dueDay = dueDate == null ? null : SubscriptionUtils.dateOnly(dueDate);
    final minStartDate = dueDay?.add(const Duration(days: 1));
    final initialStartDate = minStartDate == null
        ? today
        : today.isAfter(dueDay!)
        ? today
        : minStartDate;
    final initialEndDate = SubscriptionUtils.calculateNextBillingDate(
      initialStartDate,
      device.cycleType!,
    );

    final result = await showDialog<RenewDialogResult>(
      context: context,
      builder: (dialogContext) => RenewDialog(
        initialCycleType: device.cycleType!,
        initialPrice: device.periodPrice ?? device.price,
        initialRecordDate: today,
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
        previousEndDate: dueDate,
      ),
    );
    if (result == null || !context.mounted) return;

    if (dueDate != null &&
        !SubscriptionUtils.dateOnly(
          result.startDate,
        ).isAfter(SubscriptionUtils.dateOnly(dueDate))) {
      AppToast.show(context, '续费开始日期不能和上一期重复', isError: true);
      return;
    }

    try {
      final historyEntry = SubscriptionHistory()
        ..startDate = result.startDate
        ..endDate = result.endDate
        ..price = result.price
        ..isAutoRenew = false
        ..cycleType = result.cycleType
        ..recordDate = result.recordDate
        ..note = '手动续费';
      final previousTotal = _subscriptionTotal(device);
      final histories = device.history.toList()..add(historyEntry);

      device
        ..history = histories
        ..cycleType = result.cycleType
        ..price = result.price
        ..periodPrice = result.price
        ..nextBillingDate = result.endDate
        ..totalAccumulatedPrice = previousTotal + result.price;

      await ref.read(deviceRepositoryProvider).updateDevice(device);
      await _syncSubscriptionNotification(ref, device);
      ref.invalidate(deviceDetailProvider(id));
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
      if (!context.mounted) return;
      AppToast.show(context, '续费成功');
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(context, '续费失败: ${userErrorMessage(e)}', isError: true);
    }
  }

  Future<void> _toggleReminder(
    BuildContext context,
    WidgetRef ref,
    Device device,
    bool enabled,
  ) async {
    final previousReminderDays = device.reminderDays;
    final previousHasReminder = device.hasReminder;

    try {
      device
        ..hasReminder = enabled
        ..reminderDays = enabled ? _defaultReminderDays(device) : 0;

      await ref.read(deviceRepositoryProvider).updateDevice(device);
      await _syncSubscriptionNotification(ref, device);
      ref.invalidate(deviceDetailProvider(id));
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
      if (!context.mounted) return;
      AppToast.show(context, enabled ? '已开启到期提醒' : '已关闭到期提醒');
    } catch (e) {
      device
        ..hasReminder = previousHasReminder
        ..reminderDays = previousReminderDays;
      if (!context.mounted) return;
      AppToast.show(context, '提醒设置失败: ${userErrorMessage(e)}', isError: true);
    }
  }

  Future<void> _syncSubscriptionNotification(WidgetRef ref, Device device) {
    final subscriptionService = ref.read(subscriptionServiceProvider);
    if (device.hasReminder && device.subscriptionDueDate != null) {
      return subscriptionService.scheduleSubscriptionNotification(device);
    }
    return subscriptionService.cancelSubscriptionNotification(device);
  }

  int _defaultReminderDays(Device device) {
    if (device.reminderDays > 0) return device.reminderDays;
    return 3;
  }

  double _subscriptionTotal(Device device) {
    if (device.history.isEmpty) return device.totalAccumulatedPrice;
    return device.history.fold<double>(
      0,
      (total, history) => total + history.price,
    );
  }

  Widget _buildTagsSection(Device device, ThemeData theme) {
    if (device.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: device.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '#$tag',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesSection(String notes, ThemeData theme) {
    return BaseCard(
      variant: CardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, color: AppColors.ash, size: 20),
              const SizedBox(width: 8),
              Text(
                '备注',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(notes, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSubscriptionHistory(Device device, ThemeData theme) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final periods = _subscriptionPeriods(device);

    return BaseCard(
      variant: CardVariant.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.ash, size: 20),
              const SizedBox(width: 8),
              Text(
                '订阅记录',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '共 ${periods.length} 期',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.ash,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (periods.isEmpty)
            Text(
              '暂无订阅记录',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.ash),
            )
          else
            ...periods.map((period) {
              return Padding(
                padding: EdgeInsets.only(
                  top: period.index == 1 ? 0 : 12,
                  bottom: period.index == periods.length ? 0 : 12,
                ),
                child: _SubscriptionPeriodTile(
                  period: period,
                  dateFormat: dateFormat,
                  theme: theme,
                ),
              );
            }),
        ],
      ),
    );
  }

  List<_SubscriptionPeriod> _subscriptionPeriods(Device device) {
    final histories = [...device.history]
      ..sort((a, b) {
        final aDate =
            a.startDate ??
            a.recordDate ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.startDate ??
            b.recordDate ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

    final source = histories.isEmpty
        ? [
            SubscriptionHistory()
              ..startDate = device.purchaseDate
              ..endDate = device.subscriptionDueDate
              ..price = device.price
              ..cycleType = device.cycleType ?? CycleType.monthly
              ..recordDate = device.purchaseDate,
          ]
        : histories;

    return source.asMap().entries.map((entry) {
      final history = entry.value;
      return _SubscriptionPeriod(
        index: entry.key + 1,
        history: history,
        status: _periodStatus(history),
      );
    }).toList();
  }

  int _currentPeriodNumber(List<_SubscriptionPeriod> periods, Device device) {
    return _currentPeriod(periods, device)?.index ?? 0;
  }

  _SubscriptionPeriod? _currentPeriod(
    List<_SubscriptionPeriod> periods,
    Device device,
  ) {
    if (periods.isEmpty) return null;
    final activeIndex = periods.indexWhere(
      (period) => period.status == _SubscriptionPeriodStatus.active,
    );
    if (activeIndex >= 0) return periods[activeIndex];

    final dueDate = device.subscriptionDueDate;
    if (dueDate != null) {
      final dueDay = SubscriptionUtils.dateOnly(dueDate);
      final dueIndex = periods.indexWhere((period) {
        final end = period.history.endDate;
        return end != null && SubscriptionUtils.dateOnly(end) == dueDay;
      });
      if (dueIndex >= 0) return periods[dueIndex];
    }

    return periods.last;
  }

  _SubscriptionPeriodStatus _periodStatus(SubscriptionHistory history) {
    final start = history.startDate;
    final end = history.endDate;
    if (start == null || end == null) return _SubscriptionPeriodStatus.unknown;

    final today = SubscriptionUtils.dateOnly(DateTime.now());
    final startDay = SubscriptionUtils.dateOnly(start);
    final endDay = SubscriptionUtils.dateOnly(end);
    if (today.isBefore(startDay)) return _SubscriptionPeriodStatus.upcoming;
    if (today.isAfter(endDay)) return _SubscriptionPeriodStatus.ended;
    return _SubscriptionPeriodStatus.active;
  }
}

enum _SubscriptionPeriodStatus { active, upcoming, ended, unknown }

class _SubscriptionPeriod {
  final int index;
  final SubscriptionHistory history;
  final _SubscriptionPeriodStatus status;

  const _SubscriptionPeriod({
    required this.index,
    required this.history,
    required this.status,
  });
}

class _SubscriptionPeriodTile extends StatelessWidget {
  final _SubscriptionPeriod period;
  final DateFormat dateFormat;
  final ThemeData theme;

  const _SubscriptionPeriodTile({
    required this.period,
    required this.dateFormat,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final history = period.history;
    final statusColor = _statusColor(context, period.status);
    final isActive = period.status == _SubscriptionPeriodStatus.active;
    final durationDays = history.startDate != null && history.endDate != null
        ? SubscriptionUtils.dateOnly(history.endDate!)
                  .difference(SubscriptionUtils.dateOnly(history.startDate!))
                  .inDays +
              1
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? statusColor.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? statusColor.withValues(alpha: 0.65)
              : theme.dividerColor.withValues(alpha: 0.6),
          width: isActive ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: _InlineNumberText(
                        prefix: '第',
                        number: '${period.index}',
                        suffix: '期',
                        color: theme.colorScheme.onSurface,
                        numberStyle: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(
                      label: _statusLabel(period.status),
                      color: statusColor,
                    ),
                  ],
                ),
              ),
              _InlineNumberText(
                prefix: '¥',
                number: FormatUtils.formatCurrency(history.price),
                color: theme.colorScheme.error,
                numberStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PeriodInfoRow(label: '开始日期', value: _formatDate(history.startDate)),
          const SizedBox(height: 6),
          _PeriodInfoRow(label: '到期日期', value: _formatDate(history.endDate)),
          const SizedBox(height: 6),
          _PeriodInfoRow(label: '记录日期', value: _formatDate(history.recordDate)),
          const SizedBox(height: 6),
          _PeriodInfoRow(
            label: '订阅模式',
            value:
                '${SubscriptionUtils.cycleLabel(history.cycleType)}${durationDays == null ? '' : ' · $durationDays天'}',
          ),
          if (history.note != null && history.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _PeriodInfoRow(label: '备注', value: history.note!),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '未记录';
    return dateFormat.format(date);
  }

  String _statusLabel(_SubscriptionPeriodStatus status) {
    return switch (status) {
      _SubscriptionPeriodStatus.active => '当前',
      _SubscriptionPeriodStatus.upcoming => '未开始',
      _SubscriptionPeriodStatus.ended => '已结束',
      _SubscriptionPeriodStatus.unknown => '记录',
    };
  }

  Color _statusColor(BuildContext context, _SubscriptionPeriodStatus status) {
    return switch (status) {
      _SubscriptionPeriodStatus.active => Theme.of(context).colorScheme.primary,
      _SubscriptionPeriodStatus.upcoming => Colors.blueGrey,
      _SubscriptionPeriodStatus.ended => AppColors.ash,
      _SubscriptionPeriodStatus.unknown => AppColors.ash,
    };
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PeriodInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _PeriodInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.ash),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchInfoRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchInfoRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ash,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _CostMetric extends StatelessWidget {
  final String label;
  final String? prefix;
  final String number;
  final String? suffix;
  final Color valueColor;

  const _CostMetric({
    required this.label,
    this.prefix,
    required this.number,
    this.suffix,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.ash),
        ),
        const SizedBox(height: 4),
        _InlineNumberText(
          prefix: prefix,
          number: number,
          suffix: suffix,
          color: valueColor,
          numberStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InlineNumberText extends StatelessWidget {
  final String? prefix;
  final String number;
  final String? suffix;
  final Color color;
  final TextStyle? numberStyle;

  const _InlineNumberText({
    this.prefix,
    required this.number,
    this.suffix,
    required this.color,
    this.numberStyle,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.normal,
        ) ??
        TextStyle(color: color, fontSize: 12);
    final resolvedNumberStyle = (numberStyle ?? baseStyle).copyWith(
      color: color,
    );

    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null) TextSpan(text: prefix, style: baseStyle),
          TextSpan(text: number, style: resolvedNumberStyle),
          if (suffix != null) TextSpan(text: suffix, style: baseStyle),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.ash),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
