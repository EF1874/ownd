import 'package:flutter/material.dart';
import '../../../../shared/utils/format_utils.dart';
import '../../../../shared/widgets/app_text_field.dart';

class SubscriptionPricingInfo extends StatelessWidget {
  final TextEditingController priceController;
  final bool isEditing;
  final double currentPrice;
  final double totalPrice;

  const SubscriptionPricingInfo({
    super.key,
    required this.priceController,
    required this.isEditing,
    required this.currentPrice,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditing) {
      return AppTextField(
        controller: priceController,
        label: '首期价格',
        labelStyle: TextStyle(color: Theme.of(context).hintColor),
        keyboardType: TextInputType.number,
        validator: (v) => v?.isEmpty == true ? '请输入首期价格' : null,
      );
    }

    return Row(
      children: [
        Expanded(
          child: _ReadonlyPriceField(label: '本期价格', value: currentPrice),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ReadonlyPriceField(label: '累计支出', value: totalPrice),
        ),
      ],
    );
  }
}

class _ReadonlyPriceField extends StatelessWidget {
  final String label;
  final double value;

  const _ReadonlyPriceField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: Text(
        '¥${FormatUtils.formatCurrency(value)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}
