import 'package:flutter/material.dart';
import '../../../../data/models/device.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/subscription_cycle_mode_selector.dart';
import '../../../../shared/widgets/subscription_cycle_dropdown.dart';

class SubscriptionSettingsInfo extends StatelessWidget {
  final CycleType? cycleType;
  final CycleCalculationMode cycleCalculationMode;
  final int? cycleDays;
  final bool isAutoRenew;
  final int reminderDays;
  final TextEditingController renewalPriceController;

  final Function(CycleType?) onCycleTypeChanged;
  final Function(CycleCalculationMode, int?) onCycleCalculationChanged;
  final Function(bool) onAutoRenewChanged;
  final Function(int) onReminderDaysChanged;

  const SubscriptionSettingsInfo({
    super.key,
    required this.cycleType,
    required this.cycleCalculationMode,
    required this.cycleDays,
    required this.isAutoRenew,
    required this.reminderDays,
    required this.renewalPriceController,
    required this.onCycleTypeChanged,
    required this.onCycleCalculationChanged,
    required this.onAutoRenewChanged,
    required this.onReminderDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cycle & Auto Renew
        Row(
          children: [
            Expanded(
              child: SubscriptionCycleDropdown(
                value: cycleType,
                label: isAutoRenew ? '后续周期' : '周期类型',
                onChanged: onCycleTypeChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 58,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('自动续费'),
                    Switch(value: isAutoRenew, onChanged: onAutoRenewChanged),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (isAutoRenew &&
            cycleType != null &&
            cycleType != CycleType.oneTime) ...[
          AppTextField(
            controller: renewalPriceController,
            label: '续费价格',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          SubscriptionCycleModeSelector(
            cycleType: cycleType!,
            calculationMode: cycleCalculationMode,
            cycleDays: cycleDays,
            onChanged: onCycleCalculationChanged,
          ),
          const SizedBox(height: 16),
        ],

        _ReminderControl(
          reminderDays: reminderDays,
          onReminderDaysChanged: onReminderDaysChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  static const _reminderOptions = [1, 3, 7];
}

class _ReminderControl extends StatelessWidget {
  final int reminderDays;
  final ValueChanged<int> onReminderDaysChanged;

  const _ReminderControl({
    required this.reminderDays,
    required this.onReminderDaysChanged,
  });

  bool get _enabled => reminderDays > 0;

  int get _selectedDays =>
      SubscriptionSettingsInfo._reminderOptions.contains(reminderDays)
      ? reminderDays
      : 3;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.normal);

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 58,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('到期提醒'),
                Switch(
                  value: _enabled,
                  onChanged: (enabled) {
                    onReminderDaysChanged(enabled ? 3 : 0);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 56,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '提前提醒',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _enabled ? _selectedDays : null,
                  hint: Text('不提醒', style: textStyle),
                  isExpanded: true,
                  isDense: true,
                  style: textStyle,
                  items: SubscriptionSettingsInfo._reminderOptions.map((days) {
                    return DropdownMenuItem(
                      value: days,
                      child: Text('$days天', style: textStyle),
                    );
                  }).toList(),
                  onChanged: _enabled
                      ? (v) => onReminderDaysChanged(v ?? _selectedDays)
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
