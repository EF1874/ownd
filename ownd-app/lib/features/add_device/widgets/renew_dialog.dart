import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/device.dart';

class RenewDialog extends StatefulWidget {
  final CycleType initialCycleType;
  final double initialPrice;

  const RenewDialog({
    super.key,
    required this.initialCycleType,
    required this.initialPrice,
  });

  @override
  State<RenewDialog> createState() => _RenewDialogState();
}

class _RenewDialogState extends State<RenewDialog> {
  late CycleType _selectedCycle;
  late double _renewPrice;
  late DateTime _renewalDate;

  @override
  void initState() {
    super.initState();
    _selectedCycle = widget.initialCycleType;
    _renewPrice = widget.initialPrice;
    _renewalDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('手动续费'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<CycleType>(
            decoration: const InputDecoration(labelText: '续费周期'),
            initialValue: _selectedCycle,
            items:
                [
                  CycleType.daily,
                  CycleType.weekly,
                  CycleType.monthly,
                  CycleType.quarterly,
                  CycleType.yearly,
                ].map((e) {
                  String label;
                  switch (e) {
                    case CycleType.daily:
                      label = '1天';
                      break;
                    case CycleType.weekly:
                      label = '1周';
                      break;
                    case CycleType.monthly:
                      label = '1月';
                      break;
                    case CycleType.quarterly:
                      label = '1季';
                      break;
                    case CycleType.yearly:
                      label = '1年';
                      break;
                    default:
                      label = '';
                  }
                  return DropdownMenuItem(value: e, child: Text(label));
                }).toList(),
            onChanged: (v) => setState(() => _selectedCycle = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _renewPrice.toString(),
            decoration: const InputDecoration(labelText: '续费金额'),
            keyboardType: TextInputType.number,
            onChanged: (v) => _renewPrice = double.tryParse(v) ?? 0.0,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _renewalDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _renewalDate = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '续费日期',
                border: OutlineInputBorder(),
              ),
              child: Text(DateFormat('yyyy-MM-dd').format(_renewalDate)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, {
              'cycle': _selectedCycle,
              'price': _renewPrice,
              'date': _renewalDate,
            });
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}
