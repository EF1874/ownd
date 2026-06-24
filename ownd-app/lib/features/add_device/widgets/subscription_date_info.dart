import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/utils/subscription_utils.dart';

class SubscriptionDateInfo extends StatelessWidget {
  final DateTime purchaseDate;
  final DateTime? nextBillingDate;
  final bool isEditing;
  final VoidCallback onPickDate;
  final VoidCallback onPickBillingDate;

  const SubscriptionDateInfo({
    super.key,
    required this.purchaseDate,
    required this.nextBillingDate,
    required this.isEditing,
    required this.onPickDate,
    required this.onPickBillingDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    if (isEditing) {
      return Row(
        children: [
          Expanded(
            child: _ReadonlyDateField(
              label: '开始日期',
              value: dateFormat.format(purchaseDate),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ReadonlyDateField(
              label: '到期日',
              value: nextBillingDate == null
                  ? '未设置'
                  : dateFormat.format(nextBillingDate!),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onPickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '开始日期',
                border: OutlineInputBorder(),
              ),
              child: Text(dateFormat.format(purchaseDate)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: onPickBillingDate,
            child: InputDecorator(
              decoration: InputDecoration(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('到期日'),
                    if (nextBillingDate != null) ...[
                      const SizedBox(width: 4),
                      Builder(
                        builder: (context) {
                          final diff = SubscriptionUtils.daysUntilDue(
                            nextBillingDate!,
                          );
                          String label;
                          Color color;
                          if (diff < 0) {
                            label = '(已过期${-diff}天)';
                            color = Colors.red;
                          } else {
                            label = '(剩余$diff天)';
                            color = SubscriptionUtils.dueColor(context, diff);
                          }
                          return Text(
                            label,
                            style: TextStyle(fontSize: 12, color: color),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                nextBillingDate != null
                    ? dateFormat.format(nextBillingDate!)
                    : '请选择',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadonlyDateField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadonlyDateField({required this.label, required this.value});

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
