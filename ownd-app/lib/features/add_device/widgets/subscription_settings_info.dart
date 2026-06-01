import 'package:flutter/material.dart';
import '../../../../data/models/device.dart';
import '../../../../shared/widgets/app_text_field.dart';

class SubscriptionSettingsInfo extends StatelessWidget {
  final CycleType? cycleType;
  final bool isAutoRenew;
  final bool hasReminder;
  final int reminderDays;
  final bool hasFirstPeriodDiscount;
  final TextEditingController firstPeriodPriceController;

  final Function(CycleType?) onCycleTypeChanged;
  final Function(bool) onAutoRenewChanged;
  final Function(bool) onReminderChanged;
  final Function(int) onReminderDaysChanged;
  final Function(bool) onDiscountChanged;

  const SubscriptionSettingsInfo({
    super.key,
    required this.cycleType,
    required this.isAutoRenew,
    required this.hasReminder,
    required this.reminderDays,
    required this.hasFirstPeriodDiscount,
    required this.firstPeriodPriceController,
    required this.onCycleTypeChanged,
    required this.onAutoRenewChanged,
    required this.onReminderChanged,
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
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '周期类型',
                  errorStyle: TextStyle(height: 0),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CycleType>(
                    value: cycleType,
                    hint: const Text('周期'),
                    isExpanded: true,
                    isDense: true,
                    items: CycleType.values.map((e) {
                      String label;
                      switch (e) {
                        case CycleType.monthly:
                          label = '每月';
                          break;
                        case CycleType.yearly:
                          label = '每年';
                          break;
                        case CycleType.weekly:
                          label = '每周';
                          break;
                        case CycleType.daily:
                          label = '每天';
                          break;
                        case CycleType.quarterly:
                          label = '每季';
                          break;
                        case CycleType.oneTime:
                          label = '一次性';
                          break;
                      }
                      return DropdownMenuItem(value: e, child: Text(label));
                    }).toList(),
                    onChanged: onCycleTypeChanged,
                  ),
                ),
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

        // Reminder & Days
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
                    const Text('提醒'),
                    Switch(value: hasReminder, onChanged: onReminderChanged),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: IgnorePointer(
                ignoring: !hasReminder,
                child: Opacity(
                  opacity: hasReminder ? 1.0 : 0.5,
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: '提醒天数',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    initialValue: reminderDays,
                    items: List.generate(10, (index) => index + 1)
                        .map(
                          (d) => DropdownMenuItem(value: d, child: Text('$d天')),
                        )
                        .toList(),
                    onChanged: (v) => onReminderDaysChanged(v ?? 1),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Discount
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
      ],
    );
  }
}
