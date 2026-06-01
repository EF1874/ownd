import 'package:flutter/material.dart';
import '../../data/models/device.dart';

class SubscriptionUtils {
  static DateTime calculateNextBillingDate(
    DateTime currentBillingDate,
    CycleType cycleType,
  ) {
    switch (cycleType) {
      case CycleType.daily:
        return currentBillingDate.add(const Duration(days: 1));
      case CycleType.weekly:
        return currentBillingDate.add(const Duration(days: 7));
      case CycleType.monthly:
        int newMonth = currentBillingDate.month + 1;
        int newYear = currentBillingDate.year;
        if (newMonth > 12) {
          newMonth = 1;
          newYear++;
        }
        int daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
        int day = currentBillingDate.day;
        if (day > daysInNewMonth) day = daysInNewMonth;
        return DateTime(
          newYear,
          newMonth,
          day,
          currentBillingDate.hour,
          currentBillingDate.minute,
        );
      case CycleType.quarterly:
        int newMonth = currentBillingDate.month + 3;
        int newYear = currentBillingDate.year;
        while (newMonth > 12) {
          newMonth -= 12;
          newYear++;
        }
        int daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
        int day = currentBillingDate.day;
        if (day > daysInNewMonth) day = daysInNewMonth;
        return DateTime(
          newYear,
          newMonth,
          day,
          currentBillingDate.hour,
          currentBillingDate.minute,
        );
      case CycleType.yearly:
        int newYear = currentBillingDate.year + 1;
        int newMonth = currentBillingDate.month;
        int day = currentBillingDate.day;
        int daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
        if (day > daysInNewMonth) day = daysInNewMonth;
        return DateTime(
          newYear,
          newMonth,
          day,
          currentBillingDate.hour,
          currentBillingDate.minute,
        );
      case CycleType.oneTime:
        return currentBillingDate;
    }
  }

  static Duration getDuration(CycleType type) {
    switch (type) {
      case CycleType.daily:
        return const Duration(days: 1);
      case CycleType.weekly:
        return const Duration(days: 7);
      case CycleType.monthly:
        return const Duration(days: 30); // Approx
      case CycleType.quarterly:
        return const Duration(days: 90); // Approx
      case CycleType.yearly:
        return const Duration(days: 365); // Approx
      case CycleType.oneTime:
        return Duration.zero;
    }
  }
}
