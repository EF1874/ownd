import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/utils/subscription_utils.dart';

class SubscriptionDateInfo extends StatelessWidget {
  final DateTime purchaseDate;
  final DateTime? nextBillingDate;
  final bool isAutoRenew;
  final VoidCallback onPickDate;
  final VoidCallback onPickBillingDate;

  const SubscriptionDateInfo({
    super.key,
    required this.purchaseDate,
    required this.nextBillingDate,
    required this.isAutoRenew,
    required this.onPickDate,
    required this.onPickBillingDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

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
                    Text(isAutoRenew ? '到期/续费日' : '到期日'),
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
                          } else if (diff == 0) {
                            label = '(今天到期)';
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
