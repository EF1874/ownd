import 'package:flutter/material.dart';
import '../../../../data/models/device.dart';
import 'subscription_pricing_info.dart';
import 'subscription_date_info.dart';
import 'subscription_settings_info.dart';

class SubscriptionSection extends StatelessWidget {
  final TextEditingController priceController;
  final TextEditingController renewalPriceController;
  final DateTime purchaseDate;
  final DateTime? nextBillingDate;
  final CycleType? cycleType;
  final CycleCalculationMode cycleCalculationMode;
  final int? cycleDays;
  final bool isAutoRenew;
  final int reminderDays;

  final Function(CycleType?) onCycleTypeChanged;
  final Function(CycleCalculationMode, int?) onCycleCalculationChanged;
  final Function(bool) onAutoRenewChanged;
  final Function(int) onReminderDaysChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickBillingDate;

  const SubscriptionSection({
    super.key,
    required this.priceController,
    required this.renewalPriceController,
    required this.purchaseDate,
    required this.nextBillingDate,
    required this.cycleType,
    required this.cycleCalculationMode,
    required this.cycleDays,
    required this.isAutoRenew,
    required this.reminderDays,
    required this.onCycleTypeChanged,
    required this.onCycleCalculationChanged,
    required this.onAutoRenewChanged,
    required this.onReminderDaysChanged,
    required this.onPickDate,
    required this.onPickBillingDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SubscriptionPricingInfo(priceController: priceController),
        const SizedBox(height: 16),
        SubscriptionDateInfo(
          purchaseDate: purchaseDate,
          nextBillingDate: nextBillingDate,
          isAutoRenew: isAutoRenew,
          onPickDate: onPickDate,
          onPickBillingDate: onPickBillingDate,
        ),
        const SizedBox(height: 16),
        SubscriptionSettingsInfo(
          cycleType: cycleType,
          cycleCalculationMode: cycleCalculationMode,
          cycleDays: cycleDays,
          isAutoRenew: isAutoRenew,
          reminderDays: reminderDays,
          renewalPriceController: renewalPriceController,
          onCycleTypeChanged: onCycleTypeChanged,
          onCycleCalculationChanged: onCycleCalculationChanged,
          onAutoRenewChanged: onAutoRenewChanged,
          onReminderDaysChanged: onReminderDaysChanged,
        ),
      ],
    );
  }
}
