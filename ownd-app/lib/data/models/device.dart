import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'category.dart';
import '../../shared/utils/subscription_utils.dart';

part 'device.g.dart';

enum CycleType {
  daily,
  weekly,
  monthly,
  quarterly,
  halfYearly,
  yearly,
  oneTime,
}

enum CycleCalculationMode { calendar, fixedDays }

@Collection()
class Device {
  Id id = Isar.autoIncrement;

  String uuid = const Uuid().v4();

  late String name;

  double price = 0.0;

  double? renewalPrice;
  double? periodPrice;
  double _totalAccumulatedPrice = 0.0;

  DateTime purchaseDate = DateTime.now();

  DateTime? warrantyEndDate;
  DateTime? backupDate;
  DateTime? scrapDate;
  String? platform;

  @ignore
  String? platformUuid;

  String? customIconPath;

  final category = IsarLink<Category>();

  @Enumerated(EnumType.name)
  CycleType? cycleType;

  @Enumerated(EnumType.name)
  CycleCalculationMode cycleCalculationMode = CycleCalculationMode.calendar;
  int? cycleDays;

  bool isAutoRenew = false;
  DateTime? nextBillingDate;
  bool hasReminder = false;

  // --- New fields for v1.2 ---
  String? imagePath;
  String? notes;
  List<String> tags = [];
  int usageCount = 0;
  DateTime? lastUsedDate;
  double? expectedLifeYears;

  List<SubscriptionHistory> history = [];

  double get totalAccumulatedPrice {
    return _totalAccumulatedPrice > 0 ? _totalAccumulatedPrice : price;
  }

  set totalAccumulatedPrice(double value) {
    _totalAccumulatedPrice = value;
  }

  double get dailyCost {
    if (cycleType == null) {
      // For normal items, calculate amortized daily cost
      final days = daysUsed;
      if (days < 1) return price; // First day or invalid dates
      return price / days;
    }

    final totalCost = history.isEmpty
        ? totalAccumulatedPrice
        : history.fold<double>(0, (total, h) => total + h.price);
    final totalDays = subscriptionDaysUsed();
    if (totalDays <= 0) return 0.0;
    return totalCost / totalDays;
  }

  int subscriptionDaysUsed({DateTime? asOf}) {
    if (cycleType == null) return daysUsed;

    final today = SubscriptionUtils.dateOnly(asOf ?? DateTime.now());
    final intervals = <({DateTime start, DateTime end})>[];

    if (history.isEmpty && nextBillingDate != null) {
      intervals.add((
        start: SubscriptionUtils.dateOnly(purchaseDate),
        end: SubscriptionUtils.dateOnly(nextBillingDate!),
      ));
    } else {
      for (final item in history) {
        final start = item.startDate;
        final end = item.endDate;
        if (start == null || end == null) continue;
        intervals.add((
          start: SubscriptionUtils.dateOnly(start),
          end: SubscriptionUtils.dateOnly(end),
        ));
      }
    }

    if (intervals.isEmpty) return 0;

    intervals.sort((a, b) => a.start.compareTo(b.start));
    var totalDays = 0;
    DateTime? mergedStart;
    DateTime? mergedEnd;

    void flushMerged() {
      final start = mergedStart;
      final end = mergedEnd;
      if (start == null || end == null) return;
      final clippedEnd = end.isAfter(today) ? today : end;
      if (clippedEnd.isBefore(start)) return;
      totalDays += clippedEnd.difference(start).inDays + 1;
    }

    for (final interval in intervals) {
      if (interval.start.isAfter(today)) continue;
      final intervalEnd = interval.end.isAfter(today) ? today : interval.end;
      if (intervalEnd.isBefore(interval.start)) continue;

      if (mergedStart == null || mergedEnd == null) {
        mergedStart = interval.start;
        mergedEnd = intervalEnd;
        continue;
      }

      final currentEnd = mergedEnd;
      final nextDay = currentEnd.add(const Duration(days: 1));
      if (!interval.start.isAfter(nextDay)) {
        if (intervalEnd.isAfter(currentEnd)) mergedEnd = intervalEnd;
      } else {
        flushMerged();
        mergedStart = interval.start;
        mergedEnd = intervalEnd;
      }
    }

    flushMerged();
    return totalDays;
  }

  DateTime? get subscriptionDueDate {
    final endDates =
        history
            .map((item) => item.endDate)
            .whereType<DateTime>()
            .map(SubscriptionUtils.dateOnly)
            .toList()
          ..sort((a, b) => a.compareTo(b));

    final historyDueDate = endDates.isEmpty ? null : endDates.last;
    final savedDueDate = nextBillingDate == null
        ? null
        : SubscriptionUtils.dateOnly(nextBillingDate!);

    if (historyDueDate == null) return savedDueDate;
    if (savedDueDate == null) return historyDueDate;
    return savedDueDate.isAfter(historyDueDate) ? savedDueDate : historyDueDate;
  }

  int get daysUsed {
    final end = scrapDate ?? DateTime.now();
    return end.difference(purchaseDate).inDays;
  }

  String get status {
    if (scrapDate != null) {
      return 'scrap';
    }
    if (backupDate != null) {
      return 'backup';
    }
    return 'active';
  }

  /// Cost per use = total price / usage count.
  /// Returns null if usageCount is 0.
  @ignore
  double? get perUseCost {
    if (usageCount <= 0) return null;
    return price / usageCount;
  }

  /// Depreciated current value using straight-line depreciation.
  /// currentValue = price * (1 - daysUsed / expectedLifeDays)
  /// Returns null if expectedLifeYears is not set.
  @ignore
  double? get currentValue {
    if (expectedLifeYears == null || expectedLifeYears! <= 0) return null;
    final expectedDays = (expectedLifeYears! * 365).round();
    final used = daysUsed;
    if (used >= expectedDays) return 0.0;
    return price * (1 - used / expectedDays);
  }

  /// Whether this item is considered idle (no usage in N days).
  bool isIdle({int thresholdDays = 90}) {
    if (lastUsedDate == null) {
      // If never used and owned for more than threshold days
      return daysUsed > thresholdDays;
    }
    return DateTime.now().difference(lastUsedDate!).inDays > thresholdDays;
  }

  void snapshotCurrentSubscription({
    required DateTime endDate,
    DateTime? recordDate,
  }) {
    if (cycleType == null) return;

    final historyEntry = SubscriptionHistory()
      ..endDate = endDate
      ..price = price
      ..isAutoRenew = false
      ..cycleType = cycleType!
      ..cycleCalculationMode = cycleCalculationMode
      ..cycleDays = cycleDays
      ..recordDate = recordDate;

    DateTime calculatedStart;
    if (cycleCalculationMode == CycleCalculationMode.fixedDays) {
      final days =
          cycleDays ?? SubscriptionUtils.defaultFixedCycleDays(cycleType!);
      calculatedStart = endDate.subtract(Duration(days: days - 1));
    } else {
      calculatedStart = endDate
          .subtract(SubscriptionUtils.getDuration(cycleType!))
          .add(const Duration(days: 1));
    }

    // If history is not empty, we assume the calculated start is correct based on the duration.
    // We do NOT force it to match legacy end date to preserve gaps.
    if (history.isEmpty) {
      calculatedStart = purchaseDate;
    }

    // Ensure list is growable
    history = history.toList();
    historyEntry.startDate = calculatedStart;
    history.add(historyEntry);
  }
}

@Embedded()
class SubscriptionHistory {
  @ignore
  String? uuid;

  DateTime? startDate;
  DateTime? endDate;
  double price = 0.0;

  @Enumerated(EnumType.name)
  CycleType cycleType = CycleType.monthly;

  @Enumerated(EnumType.name)
  CycleCalculationMode cycleCalculationMode = CycleCalculationMode.calendar;
  int? cycleDays;

  bool isAutoRenew = false;

  DateTime? recordDate;
  String? note;
}
