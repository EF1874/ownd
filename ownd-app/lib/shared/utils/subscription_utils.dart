import 'package:flutter/material.dart';
import '../../data/models/device.dart';

class SubscriptionUtils {
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime calculateNextBillingDate(
    DateTime currentBillingDate,
    CycleType cycleType,
  ) {
    return calculateDueDate(currentBillingDate, cycleType);
  }

  static DateTime calculateDueDate(DateTime startDate, CycleType cycleType) {
    final start = dateOnly(startDate);
    switch (cycleType) {
      case CycleType.daily:
        return start;
      case CycleType.weekly:
        return start.add(const Duration(days: 6));
      case CycleType.monthly:
        int newMonth = start.month + 1;
        int newYear = start.year;
        if (newMonth > 12) {
          newMonth = 1;
          newYear++;
        }
        int daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
        int day = start.day;
        if (day > daysInNewMonth) day = daysInNewMonth;
        return DateTime(
          newYear,
          newMonth,
          day,
        ).subtract(const Duration(days: 1));
      case CycleType.quarterly:
        int newMonth = start.month + 3;
        int newYear = start.year;
        while (newMonth > 12) {
          newMonth -= 12;
          newYear++;
        }
        int daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
        int day = start.day;
        if (day > daysInNewMonth) day = daysInNewMonth;
        return DateTime(
          newYear,
          newMonth,
          day,
        ).subtract(const Duration(days: 1));
      case CycleType.yearly:
        int newYear = start.year + 1;
        int newMonth = start.month;
        int day = start.day;
        int daysInNewMonth = DateUtils.getDaysInMonth(newYear, newMonth);
        if (day > daysInNewMonth) day = daysInNewMonth;
        return DateTime(
          newYear,
          newMonth,
          day,
        ).subtract(const Duration(days: 1));
      case CycleType.oneTime:
        return start;
    }
  }

  static DateTime advanceDueDate(DateTime dueDate, CycleType cycleType) {
    return calculateDueDate(
      dateOnly(dueDate).add(const Duration(days: 1)),
      cycleType,
    );
  }

  static int daysUntilDue(DateTime dueDate, {DateTime? from}) {
    final today = dateOnly(from ?? DateTime.now());
    return dateOnly(dueDate).difference(today).inDays;
  }

  static Color dueColor(BuildContext context, int daysUntilDue) {
    if (daysUntilDue <= 1) return Colors.red;
    if (daysUntilDue <= 3) return Colors.deepOrange;
    if (daysUntilDue <= 7) return Colors.orange;
    return Theme.of(context).colorScheme.primary;
  }

  static String cycleLabel(CycleType? cycleType) {
    switch (cycleType) {
      case CycleType.monthly:
        return '月';
      case CycleType.yearly:
        return '年';
      case CycleType.weekly:
        return '周';
      case CycleType.daily:
        return '天';
      case CycleType.quarterly:
        return '季';
      case CycleType.oneTime:
        return '一次性';
      case null:
        return '未设置';
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
