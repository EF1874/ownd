import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/device.dart';
import '../../../shared/utils/subscription_utils.dart';
import '../../../shared/widgets/subscription_cycle_dropdown.dart';

class RenewDialogResult {
  final CycleType cycleType;
  final double price;
  final DateTime recordDate;
  final DateTime startDate;
  final DateTime endDate;

  const RenewDialogResult({
    required this.cycleType,
    required this.price,
    required this.recordDate,
    required this.startDate,
    required this.endDate,
  });
}

class RenewDialog extends StatefulWidget {
  final CycleType initialCycleType;
  final double initialPrice;
  final DateTime initialRecordDate;
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final DateTime? previousEndDate;

  const RenewDialog({
    super.key,
    required this.initialCycleType,
    required this.initialPrice,
    required this.initialRecordDate,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.previousEndDate,
  });

  @override
  State<RenewDialog> createState() => _RenewDialogState();
}

class _RenewDialogState extends State<RenewDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late CycleType _selectedCycle;
  late DateTime _recordDate;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _endDateEdited = false;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _selectedCycle = widget.initialCycleType;
    _recordDate = widget.initialRecordDate;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _priceController = TextEditingController(
      text: widget.initialPrice % 1 == 0
          ? widget.initialPrice.toInt().toString()
          : widget.initialPrice.toString(),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final minStartDate = widget.previousEndDate == null
        ? null
        : SubscriptionUtils.dateOnly(
            widget.previousEndDate!,
          ).add(const Duration(days: 1));

    return AlertDialog(
      title: const Text('手动续费'),
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
                label: '续费日期',
                date: _recordDate,
                textStyle: textTheme.bodyMedium,
                onPick: () => _pickDate(
                  initialDate: _recordDate,
                  onPicked: (date) => setState(() => _recordDate = date),
                ),
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
                      _dateError = null;
                      _startDate = date;
                      _updateEndDateIfNeeded();
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
                      _dateError = null;
                      _endDate = date;
                      _endDateEdited = true;
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
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final previousEndDate = widget.previousEndDate;
    if (previousEndDate != null) {
      final previousEndDay = SubscriptionUtils.dateOnly(previousEndDate);
      if (!SubscriptionUtils.dateOnly(_startDate).isAfter(previousEndDay)) {
        setState(() => _dateError = '开始日期需晚于上一期到期日');
        return;
      }
      if (!SubscriptionUtils.dateOnly(_endDate).isAfter(previousEndDay)) {
        setState(() => _dateError = '到期日期需晚于上一期到期日');
        return;
      }
    }
    if (_endDate.isBefore(_startDate)) {
      setState(() => _dateError = '到期日期不能早于开始日期');
      return;
    }

    Navigator.pop(
      context,
      RenewDialogResult(
        cycleType: _selectedCycle,
        price: double.parse(_priceController.text.trim()),
        recordDate: _recordDate,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
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
