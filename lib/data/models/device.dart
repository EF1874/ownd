import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
import 'category.dart';
import '../../shared/utils/subscription_utils.dart';

part 'device.g.dart';

enum CycleType { daily, weekly, monthly, quarterly, yearly, oneTime }

@Collection()
class Device {
  Id id = Isar.autoIncrement;

  String uuid = const Uuid().v4();

  late String name;

  double price = 0.0;

  double? firstPeriodPrice;
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

  bool isAutoRenew = false;
  DateTime? nextBillingDate;
  int reminderDays = 1;
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

    // 2. Subscription Device: Calculate Historical Average Daily Cost
    double totalCost = 0.0;
    int totalDays = 0;

    // A. Sum History
    for (var h in history) {
      if (h.startDate != null && h.endDate != null) {
        totalCost += h.price;
        // Ensure we count at least 1 day
        final days = h.endDate!.difference(h.startDate!).inDays;
        totalDays += days > 0 ? days : 1;
      }
    }

    // B. Add Current Active Period
    final currentCost = periodPrice ?? price;
    totalCost += currentCost;

    // Use SubscriptionUtils.getDuration to match snapshot logic exactly
    final currentDuration = SubscriptionUtils.getDuration(cycleType!);
    // If oneTime, duration might be 0.
    if (cycleType != CycleType.oneTime) {
      totalDays += currentDuration.inDays > 0 ? currentDuration.inDays : 1;
    }

    if (totalDays <= 0) return 0.0;
    return totalCost / totalDays;
  }

  int get daysUsed {
    final end = scrapDate ?? DateTime.now();
    return end.difference(purchaseDate).inDays;
  }

  String get status {
    if (scrapDate != null && scrapDate!.isBefore(DateTime.now())) {
      return 'scrap';
    }
    if (backupDate != null && backupDate!.isBefore(DateTime.now())) {
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
      ..recordDate = recordDate;

    DateTime calculatedStart = endDate.subtract(
      SubscriptionUtils.getDuration(cycleType!),
    );

    // If history is not empty, we assume the calculated start is correct based on the duration.
    // We do NOT force it to match legacy end date to preserve gaps.
    if (history.isEmpty) {
      if (calculatedStart.isBefore(purchaseDate)) {
        calculatedStart = purchaseDate;
      }
    }

    // Ensure list is growable
    history = history.toList();
    historyEntry.startDate = calculatedStart;
    history.add(historyEntry);
  }
}

@Embedded()
class SubscriptionHistory {
  DateTime? startDate;
  DateTime? endDate;
  double price = 0.0;

  @Enumerated(EnumType.name)
  CycleType cycleType = CycleType.monthly;

  bool isAutoRenew = false;

  DateTime? recordDate;
  String? note;
}
