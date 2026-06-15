import 'package:flutter/material.dart';

import '../../data/models/device.dart';
import '../utils/subscription_utils.dart';

class SubscriptionCycleModeSelector extends StatefulWidget {
  final CycleType cycleType;
  final CycleCalculationMode calculationMode;
  final int? cycleDays;
  final void Function(CycleCalculationMode mode, int? days) onChanged;

  const SubscriptionCycleModeSelector({
    super.key,
    required this.cycleType,
    required this.calculationMode,
    required this.cycleDays,
    required this.onChanged,
  });

  @override
  State<SubscriptionCycleModeSelector> createState() =>
      _SubscriptionCycleModeSelectorState();
}

class _SubscriptionCycleModeSelectorState
    extends State<SubscriptionCycleModeSelector> {
  late final TextEditingController _daysController;
  late final FocusNode _daysFocusNode;

  @override
  void initState() {
    super.initState();
    _daysController = TextEditingController(text: _currentDaysText());
    _daysFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant SubscriptionCycleModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = _currentDaysText();
    if (_daysController.text != nextText &&
        widget.calculationMode == CycleCalculationMode.fixedDays) {
      _daysController.text = nextText;
    }
  }

  @override
  void dispose() {
    _daysController.dispose();
    _daysFocusNode.dispose();
    super.dispose();
  }

  String get _selectedValue {
    if (widget.calculationMode == CycleCalculationMode.calendar) {
      return 'calendar';
    }
    return 'custom';
  }

  String _currentDaysText() {
    return '${widget.cycleDays ?? SubscriptionUtils.defaultFixedCycleDays(widget.cycleType)}';
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final isCustom = _selectedValue == 'custom';
    const items = [
      DropdownMenuItem(value: 'calendar', child: Text('按日历周期')),
      DropdownMenuItem(value: 'custom', child: Text('自定义天数')),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '周期计算方式',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedValue,
                  isExpanded: true,
                  isDense: true,
                  style: textStyle,
                  items: items,
                  onChanged: (value) {
                    if (value == null) return;
                    if (value == 'calendar') {
                      widget.onChanged(CycleCalculationMode.calendar, null);
                      return;
                    }
                    if (value == 'custom') {
                      final days =
                          widget.cycleDays ??
                          SubscriptionUtils.defaultFixedCycleDays(
                            widget.cycleType,
                          );
                      widget.onChanged(CycleCalculationMode.fixedDays, days);
                      _daysController.text = '$days';
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _daysFocusNode.requestFocus();
                      });
                      return;
                    }
                  },
                ),
              ),
            ),
          ),
        ),
        if (isCustom) ...[
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 56,
              child: TextFormField(
                controller: _daysController,
                focusNode: _daysFocusNode,
                decoration: const InputDecoration(
                  labelText: '天数',
                  suffixText: '天',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final days = int.tryParse((value ?? '').trim());
                  if (days == null || days <= 0) return '请输入天数';
                  return null;
                },
                onChanged: (value) {
                  final days = int.tryParse(value.trim());
                  if (days != null && days > 0) {
                    widget.onChanged(CycleCalculationMode.fixedDays, days);
                  }
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
