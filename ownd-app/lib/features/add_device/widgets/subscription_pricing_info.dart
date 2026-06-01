import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_text_field.dart';

class SubscriptionPricingInfo extends StatelessWidget {
  final TextEditingController priceController;
  final TextEditingController totalAccumulatedPriceController;

  const SubscriptionPricingInfo({
    super.key,
    required this.priceController,
    required this.totalAccumulatedPriceController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            controller: priceController,
            label: '价格',
            labelStyle: TextStyle(color: Theme.of(context).hintColor),
            keyboardType: TextInputType.number,
            validator: (v) => v?.isEmpty == true ? '请输入价格' : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppTextField(
            controller: totalAccumulatedPriceController,
            label: '总投入(多次续费总值)',
            labelStyle: TextStyle(color: Theme.of(context).hintColor),
            // helperText: '多次订阅总值',
            keyboardType: TextInputType.number,
            validator: (v) => v?.isEmpty == true ? '请输入总投入' : null,
          ),
        ),
      ],
    );
  }
}
