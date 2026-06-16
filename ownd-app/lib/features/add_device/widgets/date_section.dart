import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSection extends StatelessWidget {
  final DateTime purchaseDate;
  final DateTime? warrantyDate;
  final DateTime? backupDate;
  final DateTime? scrapDate;
  final Function(bool, bool, bool, bool) onPickDate;
  final Function(DateTime?) onClearBackupDate;
  final Function(DateTime?) onClearScrapDate;

  const DateSection({
    super.key,
    required this.purchaseDate,
    required this.warrantyDate,
    required this.backupDate,
    required this.scrapDate,
    required this.onPickDate,
    required this.onClearBackupDate,
    required this.onClearScrapDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _DateField(
                labelText: '购买日期',
                valueText: dateFormat.format(purchaseDate),
                onTap: () => onPickDate(false, false, false, false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                labelText: '保修截止',
                valueText: warrantyDate != null
                    ? dateFormat.format(warrantyDate!)
                    : '未设置',
                isEmpty: warrantyDate == null,
                onTap: () => onPickDate(true, false, false, false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateField(
                labelText: '备用日期',
                valueText: backupDate != null
                    ? dateFormat.format(backupDate!)
                    : '未设置',
                isEmpty: backupDate == null,
                suffixIcon: backupDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => onClearBackupDate(null),
                      )
                    : null,
                onTap: () => onPickDate(false, true, false, false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                labelText: '报废日期',
                valueText: scrapDate != null
                    ? dateFormat.format(scrapDate!)
                    : '未设置',
                isEmpty: scrapDate == null,
                suffixIcon: scrapDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => onClearScrapDate(null),
                      )
                    : null,
                onTap: () => onPickDate(false, false, true, false),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String labelText;
  final String valueText;
  final bool isEmpty;
  final Widget? suffixIcon;
  final VoidCallback onTap;

  const _DateField({
    required this.labelText,
    required this.valueText,
    required this.onTap,
    this.isEmpty = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
          isDense: true,
        ),
        child: Text(
          valueText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: isEmpty ? TextStyle(color: Theme.of(context).hintColor) : null,
        ),
      ),
    );
  }
}
