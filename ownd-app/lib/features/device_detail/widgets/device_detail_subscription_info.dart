part of '../device_detail_screen.dart';

extension _DeviceDetailSubscriptionInfo on DeviceDetailScreen {
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
    final notificationLeadDays = ref
        .watch(preferencesServiceProvider)
        .notificationLeadDays;
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
          if (device.isAutoRenew) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '续费价格',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.ash,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '¥${FormatUtils.formatCurrency(device.renewalPrice ?? device.price)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _showRenewalPriceDialog(context, ref, device),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('修改'),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          _SwitchInfoRow(
            label: '到期提醒',
            subtitle: device.hasReminder
                ? notificationLeadDays == 0
                      ? '到期当天提醒'
                      : '到期前 $notificationLeadDays 天提醒'
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

  Future<void> _showRenewalPriceDialog(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final controller = TextEditingController(
      text: (device.renewalPrice ?? device.price).toString(),
    );

    try {
      final price = await showDialog<double>(
        context: context,
        builder: (dialogContext) {
          String? errorText;
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('修改续费价格'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '续费价格',
                  prefixText: '¥',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () {
                    final value = double.tryParse(controller.text.trim());
                    if (value == null || value < 0) {
                      setDialogState(() => errorText = '请输入正确的价格');
                      return;
                    }
                    Navigator.pop(dialogContext, value);
                  },
                  child: const Text('保存'),
                ),
              ],
            ),
          );
        },
      );
      if (price == null || !context.mounted) return;

      final previousRenewalPrice = device.renewalPrice;
      try {
        device.renewalPrice = price;
        await ref.read(deviceRepositoryProvider).updateDevice(device);
        ref.invalidate(deviceDetailProvider(id));
        await ref.read(homeDevicesNotifierProvider.notifier).silentRefresh();
        if (!context.mounted) return;
        AppToast.show(context, '续费价格已更新');
      } catch (e) {
        device.renewalPrice = previousRenewalPrice;
        if (!context.mounted) return;
        AppToast.show(
          context,
          '续费价格保存失败: ${userErrorMessage(e)}',
          isError: true,
        );
      }
    } finally {
      controller.dispose();
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
}
