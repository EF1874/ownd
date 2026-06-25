part of '../device_detail_screen.dart';

extension _DeviceDetailSubscriptionHistory on DeviceDetailScreen {
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
