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
    final theme = Theme.of(context);
    return InputDecorator(
      decoration: _disabledDecoration(context, label),
      child: Text(
        '¥${FormatUtils.formatCurrency(value)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.disabledColor,
          fontFamily: 'monospace',
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
