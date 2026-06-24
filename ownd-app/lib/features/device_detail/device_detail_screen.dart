import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add for SystemUiOverlayStyle
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../data/models/device.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/services/preferences_service.dart';
import '../../core/network/error_messages.dart';
import '../../shared/config/category_config.dart';
import '../../shared/utils/category_utils.dart';
import '../../shared/utils/icon_utils.dart';
import '../../shared/utils/format_utils.dart';
import '../../shared/utils/category_tree_utils.dart';
import '../../shared/utils/subscription_utils.dart';
import '../../shared/config/cost_config.dart';
import '../../shared/services/image_service.dart';
import '../../shared/services/subscription_service.dart';
import '../../shared/widgets/app_image.dart';
import '../../shared/widgets/base_card.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/image_preview_dialog.dart';
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
                      _buildHeaderBackground(device, theme, context, ref),
                      IgnorePointer(
                        child: Container(
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
                      ),
                      // Status bar safety gradient
                      IgnorePointer(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black54, Colors.transparent],
                              stops: [0.0, 0.4],
                            ),
                          ),
                        ),
                      ),
                      _HeaderImageButton(
                        icon: device.imagePath == null
                            ? Icons.add_a_photo_outlined
                            : Icons.camera_alt_outlined,
                        tooltip: device.imagePath == null ? '添加图片' : '更换图片',
                        onPressed: () =>
                            _changeHeaderImage(context, ref, device),
                      ),
                    ],
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: isSub
                    ? null
                    : [
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
                        _buildSubscriptionHistory(device, theme, context, ref),
                      ] else
                        _buildBasicInfoCard(device, theme),
                      if (!isSub &&
                          device.notes != null &&
                          device.notes!.isNotEmpty) ...[
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

  Widget _buildHeaderBackground(
    Device device,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
  ) {
    if (device.imagePath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => ImagePreviewDialog.show(context, device.imagePath!),
            onLongPress: () => _changeHeaderImage(context, ref, device),
            child: Hero(
              tag: 'device_image_${device.id}',
              child: AppImage(path: device.imagePath!),
            ),
          ),
        ],
      );
    }

    final color =
        CategoryUtils.getCategoryColor(device.category.value?.name) ??
        theme.colorScheme.primary;
    final item = CategoryConfig.getItem(device.category.value?.name);
    final iconData = IconUtils.getIconData(item.iconPath);

    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
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
        ),
      ],
    );
  }

  Future<void> _changeHeaderImage(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final imageService = ref.read(imageServiceProvider);
    final file = await imageService.pickAndCropImage(
      context: context,
      source: ImageSource.gallery,
      isSquare: false,
    );
    if (file == null || !context.mounted) return;

    final savedPath = await imageService.saveImageToAppDirectory(
      file,
      device.uuid,
      isIcon: false,
    );
    if (savedPath == null) {
      if (context.mounted) {
        AppToast.show(context, '图片保存失败，请重试', isError: true);
      }
      return;
    }
    if (!context.mounted) return;

    final oldImagePath = device.imagePath;
    try {
      device.imagePath = savedPath;
      await ref.read(deviceRepositoryProvider).updateDevice(device);
      if (!context.mounted) return;
      ref.invalidate(deviceDetailProvider(id));
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
      if (context.mounted) AppToast.show(context, '图片已更新');
    } catch (e) {
      device.imagePath = oldImagePath;
      if (!context.mounted) return;
      AppToast.show(context, '图片更新失败: ${userErrorMessage(e)}', isError: true);
    }
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
    final currentPeriodData = _currentPeriod(periods, device);
    final currentPeriod = currentPeriodData?.index ?? 0;
    final totalPeriods = periods.length;
    final currentHistory = currentPeriodData?.history;
    final dueDate = currentHistory?.endDate ?? device.subscriptionDueDate;
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
            label: '到期日期',
            value: dueDate == null ? '未设置' : dateFormat.format(dueDate),
          ),
          const Divider(height: 24),
          _InfoRow(
            label: '本期订阅模式',
            value: _subscriptionModeLabel(
              currentHistory?.cycleType ?? device.cycleType,
              currentHistory?.cycleCalculationMode ??
                  device.cycleCalculationMode,
              currentHistory?.cycleDays ?? device.cycleDays,
            ),
          ),
          const Divider(height: 24),
          _SwitchInfoRow(
            label: '自动续费',
            value: device.isAutoRenew,
            onChanged: (enabled) =>
                _toggleAutoRenew(context, ref, device, enabled),
          ),
          const Divider(height: 24),
          _SwitchInfoRow(
            label: '到期提醒',
            subtitle: device.hasReminder
                ? '到期前 ${ref.watch(preferencesServiceProvider).notificationLeadDays} 天提醒'
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
              label: const Text('新增订阅记录'),
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
      AppToast.show(context, '当前订阅无法新增记录', isError: true);
      return;
    }

    final today = SubscriptionUtils.dateOnly(DateTime.now());
    final currentHistory = _currentPeriod(
      _subscriptionPeriods(device),
      device,
    )?.history;
    final cycleType = currentHistory?.cycleType ?? device.cycleType!;
    final cycleCalculationMode =
        currentHistory?.cycleCalculationMode ?? device.cycleCalculationMode;
    final cycleDays = currentHistory?.cycleDays ?? device.cycleDays;
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
      cycleType,
      calculationMode: cycleCalculationMode,
      cycleDays: cycleDays,
    );

    final result = await showDialog<RenewDialogResult>(
      context: context,
      builder: (dialogContext) => RenewDialog(
        initialCycleType: cycleType,
        initialCycleCalculationMode: cycleCalculationMode,
        initialCycleDays: cycleDays,
        initialPrice:
            currentHistory?.price ?? device.periodPrice ?? device.price,
        initialRecordDate: today,
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
        previousEndDate: null,
        dateRangeValidator: (startDate, endDate) =>
            _subscriptionOverlapMessage(device.history, startDate, endDate),
      ),
    );
    if (result == null || !context.mounted) return;

    final oldDeviceHistory = device.history.toList();
    final oldNextBillingDate = device.nextBillingDate;
    final oldTotal = device.totalAccumulatedPrice;
    final oldPeriodPrice = device.periodPrice;
    final oldDevicePrice = device.price;
    final oldCycleType = device.cycleType;
    final oldCycleCalculationMode = device.cycleCalculationMode;
    final oldCycleDays = device.cycleDays;

    try {
      final historyEntry = SubscriptionHistory()
        ..startDate = result.startDate
        ..endDate = result.endDate
        ..price = result.price
        ..isAutoRenew = false
        ..cycleType = result.cycleType
        ..cycleCalculationMode = result.cycleCalculationMode
        ..cycleDays = result.cycleDays
        ..recordDate = result.recordDate
        ..note = result.note;
      final histories = device.history.toList()..add(historyEntry);

      device.history = histories;
      _recalculateSubscription(device);

      await ref.read(deviceRepositoryProvider).updateDevice(device);
      await _syncSubscriptionNotification(ref, device);
      ref.invalidate(deviceDetailProvider(id));
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
      if (!context.mounted) return;
      AppToast.show(context, '订阅记录已新增');
    } catch (e) {
      device
        ..history = oldDeviceHistory
        ..nextBillingDate = oldNextBillingDate
        ..totalAccumulatedPrice = oldTotal
        ..periodPrice = oldPeriodPrice
        ..price = oldDevicePrice
        ..cycleType = oldCycleType
        ..cycleCalculationMode = oldCycleCalculationMode
        ..cycleDays = oldCycleDays;
      if (!context.mounted) return;
      AppToast.show(context, '新增失败: ${userErrorMessage(e)}', isError: true);
    }
  }

  Future<void> _toggleAutoRenew(
    BuildContext context,
    WidgetRef ref,
    Device device,
    bool enabled,
  ) async {
    final previousAutoRenew = device.isAutoRenew;

    try {
      device.isAutoRenew = enabled;

      await ref.read(deviceRepositoryProvider).updateDevice(device);
      await _syncSubscriptionNotification(ref, device);
      ref.invalidate(deviceDetailProvider(id));
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
      if (!context.mounted) return;
      AppToast.show(context, enabled ? '已开启自动续费' : '已关闭自动续费');
    } catch (e) {
      device.isAutoRenew = previousAutoRenew;
      if (!context.mounted) return;
      AppToast.show(context, '自动续费设置失败: ${userErrorMessage(e)}', isError: true);
    }
  }

  Future<void> _toggleReminder(
    BuildContext context,
    WidgetRef ref,
    Device device,
    bool enabled,
  ) async {
    final previousHasReminder = device.hasReminder;

    try {
      device.hasReminder = enabled;

      await ref.read(deviceRepositoryProvider).updateDevice(device);
      await _syncSubscriptionNotification(ref, device);
      ref.invalidate(deviceDetailProvider(id));
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
      if (!context.mounted) return;
      AppToast.show(context, enabled ? '已开启到期提醒' : '已关闭到期提醒');
    } catch (e) {
      device.hasReminder = previousHasReminder;
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

  Widget _buildSubscriptionHistory(
    Device device,
    ThemeData theme,
    BuildContext context,
    WidgetRef ref,
  ) {
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
                  onEdit: period.canEdit
                      ? () => _showEditHistoryDialog(
                          context,
                          ref,
                          device,
                          periods,
                          period,
                        )
                      : null,
                  onDelete: period.canEdit
                      ? () =>
                            _confirmDeleteHistory(context, ref, device, period)
                      : null,
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
            a.startDate ?? a.endDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.startDate ?? b.endDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });

    final source = histories.isEmpty
        ? [
            SubscriptionHistory()
              ..startDate = device.purchaseDate
              ..endDate = device.subscriptionDueDate
              ..price = device.price
              ..cycleType = device.cycleType ?? CycleType.monthly
              ..cycleCalculationMode = device.cycleCalculationMode
              ..cycleDays = device.cycleDays
              ..recordDate = device.purchaseDate,
          ]
        : histories;

    final usingFallback = histories.isEmpty;
    return source.asMap().entries.map((entry) {
      final history = entry.value;
      return _SubscriptionPeriod(
        index: entry.key + 1,
        history: history,
        status: _periodStatus(history),
        canEdit: !usingFallback,
      );
    }).toList();
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

  Future<void> _showEditHistoryDialog(
    BuildContext context,
    WidgetRef ref,
    Device device,
    List<_SubscriptionPeriod> periods,
    _SubscriptionPeriod period,
  ) async {
    final history = period.history;
    final startDate = history.startDate;
    final endDate = history.endDate;
    if (startDate == null || endDate == null) {
      AppToast.show(context, '这条记录缺少日期，暂时无法编辑', isError: true);
      return;
    }

    final result = await showDialog<RenewDialogResult>(
      context: context,
      builder: (dialogContext) => RenewDialog(
        title: '编辑订阅记录',
        initialCycleType: history.cycleType,
        initialCycleCalculationMode: history.cycleCalculationMode,
        initialCycleDays: history.cycleDays,
        initialPrice: history.price,
        initialRecordDate: history.recordDate ?? DateTime.now(),
        initialStartDate: startDate,
        initialEndDate: endDate,
        initialNote: history.note,
        previousEndDate: null,
        dateRangeValidator: (startDate, endDate) => _subscriptionOverlapMessage(
          device.history,
          startDate,
          endDate,
          ignoredHistory: history,
        ),
      ),
    );
    if (result == null || !context.mounted) return;

    final oldHistory = SubscriptionHistory()
      ..uuid = history.uuid
      ..cycleType = history.cycleType
      ..cycleCalculationMode = history.cycleCalculationMode
      ..cycleDays = history.cycleDays
      ..price = history.price
      ..recordDate = history.recordDate
      ..startDate = history.startDate
      ..endDate = history.endDate
      ..note = history.note;
    final oldDeviceHistory = device.history.toList();
    final oldNextBillingDate = device.nextBillingDate;
    final oldTotal = device.totalAccumulatedPrice;
    final oldPeriodPrice = device.periodPrice;
    final oldDevicePrice = device.price;
    final oldCycleType = device.cycleType;
    final oldCycleCalculationMode = device.cycleCalculationMode;
    final oldCycleDays = device.cycleDays;
    history
      ..cycleType = result.cycleType
      ..cycleCalculationMode = result.cycleCalculationMode
      ..cycleDays = result.cycleDays
      ..price = result.price
      ..recordDate = result.recordDate
      ..startDate = result.startDate
      ..endDate = result.endDate
      ..note = result.note;
    _recalculateSubscription(device);

    try {
      await ref.read(deviceRepositoryProvider).updateHistory(device, history);
      await _syncSubscriptionNotification(ref, device);
      ref.invalidate(deviceDetailProvider(id));
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
      if (!context.mounted) return;
      AppToast.show(context, '订阅记录已更新');
    } catch (e) {
      history
        ..uuid = oldHistory.uuid
        ..cycleType = oldHistory.cycleType
        ..cycleCalculationMode = oldHistory.cycleCalculationMode
        ..cycleDays = oldHistory.cycleDays
        ..price = oldHistory.price
        ..recordDate = oldHistory.recordDate
        ..startDate = oldHistory.startDate
        ..endDate = oldHistory.endDate
        ..note = oldHistory.note;
      device
        ..history = oldDeviceHistory
        ..nextBillingDate = oldNextBillingDate
        ..totalAccumulatedPrice = oldTotal
        ..periodPrice = oldPeriodPrice
        ..price = oldDevicePrice
        ..cycleType = oldCycleType
        ..cycleCalculationMode = oldCycleCalculationMode
        ..cycleDays = oldCycleDays;
      if (!context.mounted) return;
      AppToast.show(context, '保存失败: ${userErrorMessage(e)}', isError: true);
    }
  }

  Future<void> _confirmDeleteHistory(
    BuildContext context,
    WidgetRef ref,
    Device device,
    _SubscriptionPeriod period,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这条订阅记录？'),
        content: const Text('删除后会重新计算累计支出和当前到期日。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final history = period.history;
    final oldDeviceHistory = device.history.toList();
    final oldNextBillingDate = device.nextBillingDate;
    final oldTotal = device.totalAccumulatedPrice;
    final oldPeriodPrice = device.periodPrice;
    final oldDevicePrice = device.price;
    final oldCycleType = device.cycleType;
    final oldCycleCalculationMode = device.cycleCalculationMode;
    final oldCycleDays = device.cycleDays;
    final histories = device.history.toList()..remove(history);
    device.history = histories;
    _recalculateSubscription(device);

    try {
      await ref.read(deviceRepositoryProvider).deleteHistory(device, history);
      await _syncSubscriptionNotification(ref, device);
      ref.invalidate(deviceDetailProvider(id));
      await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
      if (!context.mounted) return;
      AppToast.show(context, '订阅记录已删除');
    } catch (e) {
      device
        ..history = oldDeviceHistory
        ..nextBillingDate = oldNextBillingDate
        ..totalAccumulatedPrice = oldTotal
        ..periodPrice = oldPeriodPrice
        ..price = oldDevicePrice
        ..cycleType = oldCycleType
        ..cycleCalculationMode = oldCycleCalculationMode
        ..cycleDays = oldCycleDays;
      if (!context.mounted) return;
      AppToast.show(context, '删除失败: ${userErrorMessage(e)}', isError: true);
    }
  }

  void _recalculateSubscription(Device device) {
    final sorted = device.history.toList()
      ..sort((a, b) {
        final aDate = a.startDate ?? a.endDate ?? DateTime(0);
        final bDate = b.startDate ?? b.endDate ?? DateTime(0);
        return aDate.compareTo(bDate);
      });
    final latest = sorted.isEmpty ? null : sorted.last;
    final total = sorted.fold<double>(0, (sum, item) => sum + item.price);

    device
      ..history = sorted
      ..nextBillingDate = latest?.endDate
      ..totalAccumulatedPrice = total
      ..periodPrice = latest?.price ?? device.periodPrice
      ..price = latest?.price ?? device.price
      ..cycleType = latest?.cycleType ?? device.cycleType
      ..cycleCalculationMode =
          latest?.cycleCalculationMode ?? device.cycleCalculationMode
      ..cycleDays = latest?.cycleDays ?? device.cycleDays;
  }

  String _subscriptionModeLabel(
    CycleType? cycleType,
    CycleCalculationMode calculationMode,
    int? cycleDays,
  ) {
    if (cycleType == null) return '未设置';
    return '${SubscriptionUtils.cycleLabel(cycleType)} · ${SubscriptionUtils.calculationModeLabel(calculationMode, cycleDays: cycleDays)}';
  }

  String? _subscriptionOverlapMessage(
    List<SubscriptionHistory> histories,
    DateTime startDate,
    DateTime endDate, {
    SubscriptionHistory? ignoredHistory,
  }) {
    final startDay = SubscriptionUtils.dateOnly(startDate);
    final endDay = SubscriptionUtils.dateOnly(endDate);
    if (endDay.isBefore(startDay)) return '到期日期不能早于开始日期';

    for (final history in histories) {
      if (identical(history, ignoredHistory)) continue;
      final existingStart = history.startDate;
      final existingEnd = history.endDate;
      if (existingStart == null || existingEnd == null) continue;

      final existingStartDay = SubscriptionUtils.dateOnly(existingStart);
      final existingEndDay = SubscriptionUtils.dateOnly(existingEnd);
      final overlaps =
          !startDay.isAfter(existingEndDay) &&
          !endDay.isBefore(existingStartDay);
      if (overlaps) return '订阅日期不能和已有记录重叠';
    }
    return null;
  }
}

class _HeaderImageButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderImageButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 24,
      child: Material(
        color: Colors.black.withValues(alpha: 0.42),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

enum _SubscriptionPeriodStatus { active, upcoming, ended, unknown }

class _SubscriptionPeriod {
  final int index;
  final SubscriptionHistory history;
  final _SubscriptionPeriodStatus status;
  final bool canEdit;

  const _SubscriptionPeriod({
    required this.index,
    required this.history,
    required this.status,
    required this.canEdit,
  });
}

class _SubscriptionPeriodTile extends StatelessWidget {
  final _SubscriptionPeriod period;
  final DateFormat dateFormat;
  final ThemeData theme;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _SubscriptionPeriodTile({
    required this.period,
    required this.dateFormat,
    required this.theme,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final history = period.history;
    final statusStyle = _statusStyle(context, period.status);
    final durationDays = history.startDate != null && history.endDate != null
        ? SubscriptionUtils.dateOnly(history.endDate!)
                  .difference(SubscriptionUtils.dateOnly(history.startDate!))
                  .inDays +
              1
        : null;
    final isAutoRenewal = _isAutoRenewalHistory(history);
    final displayNote = _displayNote(history);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusStyle.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusStyle.border,
          width: statusStyle.borderWidth,
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
                      color: statusStyle.accent,
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
              if (onEdit != null || onDelete != null) ...[
                const SizedBox(width: 4),
                PopupMenuButton<_HistoryAction>(
                  tooltip: '记录操作',
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (action) {
                    switch (action) {
                      case _HistoryAction.edit:
                        onEdit?.call();
                        break;
                      case _HistoryAction.delete:
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _HistoryAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('编辑记录'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _HistoryAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          '删除记录',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _PeriodInfoRow(label: '开始日期', value: _formatDate(history.startDate)),
          const SizedBox(height: 6),
          _PeriodInfoRow(label: '到期日期', value: _formatDate(history.endDate)),
          const SizedBox(height: 6),
          _PeriodModeRow(
            value:
                '${SubscriptionUtils.cycleLabel(history.cycleType)} · ${SubscriptionUtils.calculationModeLabel(history.cycleCalculationMode, cycleDays: history.cycleDays)}${durationDays == null ? '' : ' · $durationDays天'}',
            showAutoRenewBadge: isAutoRenewal,
          ),
          if (displayNote != null) ...[
            const SizedBox(height: 6),
            _PeriodInfoRow(label: '备注', value: displayNote),
          ],
        ],
      ),
    );
  }

  bool _isAutoRenewalHistory(SubscriptionHistory history) {
    if (history.isAutoRenew) return true;
    return history.note?.trim().startsWith('自动续费') ?? false;
  }

  String? _displayNote(SubscriptionHistory history) {
    final note = history.note?.trim();
    if (note == null || note.isEmpty) return null;
    return note.startsWith('自动续费') ? null : note;
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

  _PeriodStatusStyle _statusStyle(
    BuildContext context,
    _SubscriptionPeriodStatus status,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (status) {
      _SubscriptionPeriodStatus.active => _PeriodStatusStyle(
        accent: colorScheme.primary,
        background: colorScheme.primary.withValues(alpha: 0.10),
        border: colorScheme.primary.withValues(alpha: 0.72),
        borderWidth: 1.6,
      ),
      _SubscriptionPeriodStatus.upcoming => _PeriodStatusStyle(
        accent: Colors.teal.shade700,
        background: Colors.teal.withValues(alpha: 0.08),
        border: Colors.teal.withValues(alpha: 0.48),
        borderWidth: 1.2,
      ),
      _SubscriptionPeriodStatus.ended => _PeriodStatusStyle(
        accent: Colors.blueGrey.shade600,
        background: Colors.blueGrey.withValues(alpha: 0.055),
        border: Colors.blueGrey.withValues(alpha: 0.24),
        borderWidth: 1,
      ),
      _SubscriptionPeriodStatus.unknown => _PeriodStatusStyle(
        accent: AppColors.ash,
        background: theme.colorScheme.surface,
        border: theme.dividerColor.withValues(alpha: 0.6),
        borderWidth: 1,
      ),
    };
  }
}

enum _HistoryAction { edit, delete }

class _PeriodStatusStyle {
  final Color accent;
  final Color background;
  final Color border;
  final double borderWidth;

  const _PeriodStatusStyle({
    required this.accent,
    required this.background,
    required this.border,
    required this.borderWidth,
  });
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

class _PeriodModeRow extends StatelessWidget {
  final String value;
  final bool showAutoRenewBadge;

  const _PeriodModeRow({required this.value, required this.showAutoRenewBadge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            '订阅模式',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.ash),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (showAutoRenewBadge)
                _InlineTag(label: '系统续期', color: theme.colorScheme.primary),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineTag extends StatelessWidget {
  final String label;
  final Color color;

  const _InlineTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
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

class _SwitchInfoRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchInfoRow({
    required this.label,
    this.subtitle,
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
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
