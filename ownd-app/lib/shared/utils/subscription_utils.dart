import 'package:flutter/material.dart';
import '../../data/models/device.dart';

class SubscriptionUtils {
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime calculateNextBillingDate(
    DateTime currentBillingDate,
    CycleType cycleType, {
    CycleCalculationMode calculationMode = CycleCalculationMode.calendar,
    int? cycleDays,
  }) {
    return calculateDueDate(
      currentBillingDate,
      cycleType,
      calculationMode: calculationMode,
      cycleDays: cycleDays,
    );
  }

  static DateTime calculateDueDate(
    DateTime startDate,
    CycleType cycleType, {
    CycleCalculationMode calculationMode = CycleCalculationMode.calendar,
    int? cycleDays,
  }) {
    final start = dateOnly(startDate);
    if (calculationMode == CycleCalculationMode.fixedDays) {
      final days = cycleDays ?? defaultFixedCycleDays(cycleType);
      return start.add(Duration(days: days - 1));
    }
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
      case CycleType.halfYearly:
        int newMonth = start.month + 6;
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

  static DateTime advanceDueDate(
    DateTime dueDate,
    CycleType cycleType, {
    CycleCalculationMode calculationMode = CycleCalculationMode.calendar,
    int? cycleDays,
  }) {
    return calculateDueDate(
      dateOnly(dueDate).add(const Duration(days: 1)),
      cycleType,
      calculationMode: calculationMode,
      cycleDays: cycleDays,
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
      case CycleType.halfYearly:
        return '半年';
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
      case CycleType.halfYearly:
        return const Duration(days: 180); // Approx
      case CycleType.yearly:
        return const Duration(days: 365); // Approx
      case CycleType.oneTime:
        return Duration.zero;
    }
  }

  static int defaultFixedCycleDays(CycleType type) {
    switch (type) {
      case CycleType.daily:
        return 1;
      case CycleType.weekly:
        return 7;
      case CycleType.monthly:
        return 30;
      case CycleType.quarterly:
        return 90;
      case CycleType.halfYearly:
        return 180;
      case CycleType.yearly:
        return 365;
      case CycleType.oneTime:
        return 1;
    }
  }

  static String calculationModeLabel(
    CycleCalculationMode mode, {
    int? cycleDays,
  }) {
    return switch (mode) {
      CycleCalculationMode.calendar => '按日历周期',
      CycleCalculationMode.fixedDays => '固定${cycleDays ?? 30}天',
    };
  }
}
