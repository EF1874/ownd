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
        // Start Date (Unified)
        InkWell(
          onTap: () => onPickDate(false, false, false, false),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '购买日期 / 开始日期',
              border: OutlineInputBorder(),
            ),
            child: Text(dateFormat.format(purchaseDate)),
          ),
        ),

        const SizedBox(height: 16),

        InkWell(
          onTap: () => onPickDate(true, false, false, false), // isWarranty
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: '保修截止日期 (可选)',
              border: OutlineInputBorder(),
            ),
            child: Text(
              warrantyDate != null ? dateFormat.format(warrantyDate!) : '未设置',
              style: warrantyDate != null
                  ? null
                  : TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => onPickDate(false, true, false, false), // isBackup
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '备用日期 (可选)',
              border: const OutlineInputBorder(),
              suffixIcon: backupDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => onClearBackupDate(null),
                    )
                  : null,
            ),
            child: Text(
              backupDate != null ? dateFormat.format(backupDate!) : '未设置',
              style: backupDate != null
                  ? null
                  : TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => onPickDate(false, false, true, false), // isScrap
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: '报废日期 (可选)',
              border: const OutlineInputBorder(),
              suffixIcon: scrapDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => onClearScrapDate(null),
                    )
                  : null,
            ),
            child: Text(
              scrapDate != null ? dateFormat.format(scrapDate!) : '未设置',
              style: scrapDate != null
                  ? null
                  : TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
        ),
      ],
    );
  }
}
