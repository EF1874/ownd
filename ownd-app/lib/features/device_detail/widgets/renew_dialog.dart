import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/device.dart';
import '../../../shared/utils/subscription_utils.dart';
import '../../../shared/widgets/subscription_cycle_mode_selector.dart';
import '../../../shared/widgets/subscription_cycle_dropdown.dart';

class RenewDialogResult {
  final CycleType cycleType;
  final CycleCalculationMode cycleCalculationMode;
  final int? cycleDays;
  final double price;
  final DateTime recordDate;
  final DateTime startDate;
  final DateTime endDate;
  final String? note;

  const RenewDialogResult({
    required this.cycleType,
    required this.cycleCalculationMode,
    this.cycleDays,
    required this.price,
    required this.recordDate,
    required this.startDate,
    required this.endDate,
    this.note,
  });
}

class RenewDialog extends StatefulWidget {
  final String title;
  final CycleType initialCycleType;
  final CycleCalculationMode initialCycleCalculationMode;
  final int? initialCycleDays;
  final double initialPrice;
  final DateTime initialRecordDate;
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final String? initialNote;
  final DateTime? previousEndDate;
  final String? Function(DateTime startDate, DateTime endDate)?
  dateRangeValidator;

  const RenewDialog({
    super.key,
    this.title = '新增订阅记录',
    required this.initialCycleType,
    this.initialCycleCalculationMode = CycleCalculationMode.calendar,
    this.initialCycleDays,
    required this.initialPrice,
    required this.initialRecordDate,
    required this.initialStartDate,
    required this.initialEndDate,
    this.initialNote,
    required this.previousEndDate,
    this.dateRangeValidator,
  });

  @override
  State<RenewDialog> createState() => _RenewDialogState();
}

class _RenewDialogState extends State<RenewDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;
  late CycleType _selectedCycle;
  late CycleCalculationMode _selectedCalculationMode;
  int? _cycleDays;
  late DateTime _recordDate;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _endDateEdited = false;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _selectedCycle = widget.initialCycleType;
    _selectedCalculationMode = widget.initialCycleCalculationMode;
    _cycleDays = widget.initialCycleDays;
    _recordDate = widget.initialRecordDate;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _priceController = TextEditingController(
      text: widget.initialPrice % 1 == 0
          ? widget.initialPrice.toInt().toString()
          : widget.initialPrice.toString(),
    );
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _noteController.addListener(_handleNoteChanged);
  }

  @override
  void dispose() {
    _noteController.removeListener(_handleNoteChanged);
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleNoteChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final minStartDate = widget.previousEndDate == null
        ? null
        : SubscriptionUtils.dateOnly(
            widget.previousEndDate!,
          ).add(const Duration(days: 1));

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SubscriptionCycleDropdown(
                value: _selectedCycle,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCycle = value;
                    _normalizeCycleDays();
                    _updateEndDateIfNeeded();
                  });
                },
              ),
              const SizedBox(height: 14),
              SubscriptionCycleModeSelector(
                cycleType: _selectedCycle,
                calculationMode: _selectedCalculationMode,
                cycleDays: _cycleDays,
                onChanged: (mode, days) {
                  setState(() {
                    _selectedCalculationMode = mode;
                    _cycleDays = days;
                    _updateEndDateIfNeeded();
                  });
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: '本期价格',
                  prefixText: '¥ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final price = double.tryParse((value ?? '').trim());
                  if (price == null || price < 0) return '请输入有效金额';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _DatePickerField(
                label: '开始日期',
                date: _startDate,
                textStyle: textTheme.bodyMedium,
                onPick: () => _pickDate(
                  initialDate: _startDate,
                  firstDate: minStartDate,
                  onPicked: (date) {
                    setState(() {
                      _startDate = date;
                      _updateEndDateIfNeeded();
                      _dateError = _validateCurrentDates();
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),
              _DatePickerField(
                label: '到期日期',
                date: _endDate,
                textStyle: textTheme.bodyMedium,
                onPick: () => _pickDate(
                  initialDate: _endDate,
                  firstDate: _startDate,
                  onPicked: (date) {
                    setState(() {
                      _endDate = date;
                      _endDateEdited = true;
                      _dateError = _validateCurrentDates();
                    });
                  },
                ),
              ),
              if (_dateError != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _dateError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: '备注',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.48,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                  suffixIcon: _noteController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '清空备注',
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: _noteController.clear,
                        ),
                ),
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
  }) async {
    final effectiveFirstDate = firstDate ?? DateTime(2000);
    final safeInitialDate = initialDate.isBefore(effectiveFirstDate)
        ? effectiveFirstDate
        : initialDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: effectiveFirstDate,
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CH'),
    );
    if (picked != null) onPicked(SubscriptionUtils.dateOnly(picked));
  }

  void _updateEndDateIfNeeded() {
    if (_endDateEdited) return;
    _endDate = SubscriptionUtils.calculateNextBillingDate(
      _startDate,
      _selectedCycle,
      calculationMode: _selectedCalculationMode,
      cycleDays: _cycleDays,
    );
  }

  void _normalizeCycleDays() {
    _selectedCalculationMode = CycleCalculationMode.calendar;
    _cycleDays = null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final dateError = _validateCurrentDates();
    if (dateError != null) {
      setState(() => _dateError = dateError);
      return;
    }

    Navigator.pop(
      context,
      RenewDialogResult(
        cycleType: _selectedCycle,
        cycleCalculationMode: _selectedCalculationMode,
        cycleDays: _selectedCalculationMode == CycleCalculationMode.fixedDays
            ? _cycleDays ??
                  SubscriptionUtils.defaultFixedCycleDays(_selectedCycle)
            : null,
        price: double.parse(_priceController.text.trim()),
        recordDate: _effectiveRecordDate(),
        startDate: _startDate,
        endDate: _endDate,
        note: _normalizedNote(),
      ),
    );
  }

  String? _normalizedNote() {
    final note = _noteController.text.trim();
    return note.isEmpty ? null : note;
  }

  DateTime _effectiveRecordDate() {
    final recordDay = SubscriptionUtils.dateOnly(_recordDate);
    final startDay = SubscriptionUtils.dateOnly(_startDate);
    return recordDay.isAfter(startDay) ? startDay : recordDay;
  }

  String? _validateCurrentDates() {
    final previousEndDate = widget.previousEndDate;
    if (previousEndDate != null) {
      final previousEndDay = SubscriptionUtils.dateOnly(previousEndDate);
      if (!SubscriptionUtils.dateOnly(_startDate).isAfter(previousEndDay)) {
        return '开始日期需晚于上一期到期日';
      }
      if (!SubscriptionUtils.dateOnly(_endDate).isAfter(previousEndDay)) {
        return '到期日期需晚于上一期到期日';
      }
    }
    if (_endDate.isBefore(_startDate)) {
      return '到期日期不能早于开始日期';
    }

    return widget.dateRangeValidator?.call(_startDate, _endDate);
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final TextStyle? textStyle;
  final VoidCallback onPick;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.textStyle,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(DateFormat('yyyy-MM-dd').format(date), style: textStyle),
      ),
    );
  }
}
