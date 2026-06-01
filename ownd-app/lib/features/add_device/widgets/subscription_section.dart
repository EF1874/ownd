import 'package:flutter/material.dart';
import '../../../../data/models/device.dart';
import 'subscription_pricing_info.dart';
import 'subscription_date_info.dart';
import 'subscription_settings_info.dart';

class SubscriptionSection extends StatelessWidget {
  final TextEditingController priceController;
  final TextEditingController firstPeriodPriceController;
  final TextEditingController totalAccumulatedPriceController;
  final DateTime purchaseDate;
  final DateTime? nextBillingDate;
  final CycleType? cycleType;
  final bool isAutoRenew;
  final bool hasReminder;
  final int reminderDays;
  final bool hasFirstPeriodDiscount;
  final Device? device;

  final Function(CycleType?) onCycleTypeChanged;
  final Function(bool) onAutoRenewChanged;
  final Function(bool) onReminderChanged;
  final Function(int) onReminderDaysChanged;
  final Function(bool) onDiscountChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickBillingDate;
  final VoidCallback onShowRenewDialog;

  const SubscriptionSection({
    super.key,
    required this.priceController,
    required this.firstPeriodPriceController,
    required this.totalAccumulatedPriceController,
    required this.purchaseDate,
    required this.nextBillingDate,
    required this.cycleType,
    required this.isAutoRenew,
    required this.hasReminder,
    required this.reminderDays,
    required this.hasFirstPeriodDiscount,
    this.device,
    required this.onCycleTypeChanged,
    required this.onAutoRenewChanged,
    required this.onReminderChanged,
    required this.onReminderDaysChanged,
    required this.onDiscountChanged,
    required this.onPickDate,
    required this.onPickBillingDate,
    required this.onShowRenewDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SubscriptionPricingInfo(
          priceController: priceController,
          totalAccumulatedPriceController: totalAccumulatedPriceController,
        ),
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
          isAutoRenew: isAutoRenew,
          hasReminder: hasReminder,
          reminderDays: reminderDays,
          hasFirstPeriodDiscount: hasFirstPeriodDiscount,
          firstPeriodPriceController: firstPeriodPriceController,
          onCycleTypeChanged: onCycleTypeChanged,
          onAutoRenewChanged: onAutoRenewChanged,
          onReminderChanged: onReminderChanged,
          onReminderDaysChanged: onReminderDaysChanged,
          onDiscountChanged: onDiscountChanged,
        ),
        if (device != null && !isAutoRenew)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onShowRenewDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('手动续费'),
            ),
          ),
      ],
    );
  }
}
