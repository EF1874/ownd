import 'package:flutter/material.dart';

import '../../data/models/device.dart';
import '../utils/subscription_utils.dart';

class SubscriptionCycleDropdown extends StatelessWidget {
  static const subscriptionCycles = [
    CycleType.daily,
    CycleType.weekly,
    CycleType.monthly,
    CycleType.quarterly,
    CycleType.yearly,
  ];

  final CycleType? value;
  final ValueChanged<CycleType?> onChanged;
  final String label;
  final String hint;
  final bool enabled;
  final List<CycleType> cycles;
  final FormFieldValidator<CycleType>? validator;

  const SubscriptionCycleDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = '周期类型',
    this.hint = '请选择周期',
    this.enabled = true,
    this.cycles = subscriptionCycles,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.normal);
    final items = _effectiveCycles();

    return DropdownButtonFormField<CycleType>(
      initialValue: value,
      isExpanded: true,
      style: textStyle,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      items: items.map((cycleType) {
        return DropdownMenuItem(
          value: cycleType,
          child: Text(
            SubscriptionUtils.cycleLabel(cycleType),
            style: textStyle,
          ),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }

  List<CycleType> _effectiveCycles() {
    final items = [...cycles];
    final selected = value;
    if (selected != null && !items.contains(selected)) {
      items.add(selected);
    }
    return items;
  }
}
