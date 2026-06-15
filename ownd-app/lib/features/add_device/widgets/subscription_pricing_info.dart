import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_text_field.dart';

class SubscriptionPricingInfo extends StatelessWidget {
  final TextEditingController priceController;

  const SubscriptionPricingInfo({super.key, required this.priceController});

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: priceController,
      label: '价格',
      labelStyle: TextStyle(color: Theme.of(context).hintColor),
      keyboardType: TextInputType.number,
      validator: (v) => v?.isEmpty == true ? '请输入价格' : null,
    );
  }
}
