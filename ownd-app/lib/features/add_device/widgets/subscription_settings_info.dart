import 'package:flutter/material.dart';
import '../../../../data/models/device.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/subscription_cycle_dropdown.dart';

class SubscriptionSettingsInfo extends StatelessWidget {
  final CycleType? cycleType;
  final bool isAutoRenew;
  final int reminderDays;
  final bool hasFirstPeriodDiscount;
  final TextEditingController firstPeriodPriceController;

  final Function(CycleType?) onCycleTypeChanged;
  final Function(bool) onAutoRenewChanged;
  final Function(int) onReminderDaysChanged;
  final Function(bool) onDiscountChanged;

  const SubscriptionSettingsInfo({
    super.key,
    required this.cycleType,
    required this.isAutoRenew,
    required this.reminderDays,
    required this.hasFirstPeriodDiscount,
    required this.firstPeriodPriceController,
    required this.onCycleTypeChanged,
    required this.onAutoRenewChanged,
    required this.onReminderDaysChanged,
    required this.onDiscountChanged,
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

        if (isAutoRenew) ...[
          Row(
            children: [
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
                      const Text('首期优惠'),
                      Switch(
                        value: hasFirstPeriodDiscount,
                        onChanged: onDiscountChanged,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppTextField(
                  controller: firstPeriodPriceController,
                  label: '首期价格',
                  enabled: hasFirstPeriodDiscount,
                  keyboardType: TextInputType.number,
                  labelStyle: TextStyle(
                    color: hasFirstPeriodDiscount
                        ? Theme.of(context).hintColor
                        : Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ],
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
      ],
    );
  }
}
