import 'package:flutter/material.dart';
import '../../../../data/models/device.dart';
import '../../../../shared/utils/subscription_utils.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/subscription_cycle_mode_selector.dart';
import '../../../../shared/widgets/subscription_cycle_dropdown.dart';

class SubscriptionSettingsInfo extends StatelessWidget {
  final CycleType? cycleType;
  final CycleCalculationMode cycleCalculationMode;
  final int? cycleDays;
  final bool isEditing;
  final bool isAutoRenew;
  final bool hasReminder;
  final TextEditingController renewalPriceController;

  final Function(CycleType?) onCycleTypeChanged;
  final Function(CycleCalculationMode, int?) onCycleCalculationChanged;
  final Function(bool) onAutoRenewChanged;
  final Function(bool) onReminderChanged;

  const SubscriptionSettingsInfo({
    super.key,
    required this.cycleType,
    required this.cycleCalculationMode,
    required this.cycleDays,
    required this.isEditing,
    required this.isAutoRenew,
    required this.hasReminder,
    required this.renewalPriceController,
    required this.onCycleTypeChanged,
    required this.onCycleCalculationChanged,
    required this.onAutoRenewChanged,
    required this.onReminderChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ReadonlySettingField(
                  label: '本期周期',
                  value: cycleType == null
                      ? '未设置'
                      : '${SubscriptionUtils.cycleLabel(cycleType)} · ${SubscriptionUtils.calculationModeLabel(cycleCalculationMode, cycleDays: cycleDays)}',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
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
            AppTextField(
              controller: renewalPriceController,
              label: '续费价格',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ],
          _ReminderControl(
            hasReminder: hasReminder,
            onReminderChanged: onReminderChanged,
          ),
          const SizedBox(height: 16),
        ],
      );
    }

    return Column(
      children: [
        // Cycle & Auto Renew
        Row(
          children: [
            Expanded(
              child: SubscriptionCycleDropdown(
                value: cycleType,
                label: '本期周期',
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
          hasReminder: hasReminder,
          onReminderChanged: onReminderChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ReadonlySettingField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadonlySettingField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: _disabledDecoration(context, label),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.disabledColor,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  InputDecoration _disabledDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor.withValues(
      alpha: dark ? 0.42 : 0.55,
    );
    return InputDecoration(
      labelText: label,
      enabled: false,
      filled: true,
      fillColor: theme.disabledColor.withValues(alpha: dark ? 0.10 : 0.06),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
    );
  }
}

class _ReminderControl extends StatelessWidget {
  final bool hasReminder;
  final ValueChanged<bool> onReminderChanged;

  const _ReminderControl({
    required this.hasReminder,
    required this.onReminderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 58,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('到期提醒'),
          Switch(value: hasReminder, onChanged: onReminderChanged),
        ],
      ),
    );
  }
}
