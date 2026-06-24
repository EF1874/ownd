import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/device.dart';
import '../../data/repositories/device_repository.dart';
import '../utils/subscription_utils.dart';
import 'notification_service.dart';
import '../../data/services/preferences_service.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  final deviceRepo = ref.watch(deviceRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final prefs = ref.watch(preferencesServiceProvider);
  return SubscriptionService(deviceRepo, notificationService, prefs);
});

class SubscriptionService {
  final DeviceRepository _deviceRepo;
  final NotificationService _notificationService;
  final PreferencesService _prefs;

  SubscriptionService(this._deviceRepo, this._notificationService, this._prefs);

  /// Checks all auto-renew subscriptions and updates them if they are due.
  Future<void> checkAndRenewSubscriptions() async {
    final devices = await _deviceRepo.getAllDevices();
    final now = DateTime.now();
    for (final device in devices) {
      bool needUpdate = false;
      // Only process auto-renew subscriptions with valid cycles
      if (device.isAutoRenew &&
          device.subscriptionDueDate != null &&
          device.cycleType != null &&
          device.cycleType != CycleType.oneTime) {
        // Check if due
        if (SubscriptionUtils.dateOnly(
          device.subscriptionDueDate!,
        ).isBefore(SubscriptionUtils.dateOnly(now))) {
          bool renewed = _processRenewal(device, now);
          if (renewed) {
            needUpdate = true;
          }
        }
      }

      if (needUpdate) {
        // Update DB
        await _deviceRepo.updateDevice(device);
        // Reschedule notification for the new date
        await scheduleSubscriptionNotification(device);
      }
    }
  }

  Future<void> scheduleSubscriptionNotification(Device device) async {
    final billingDate = device.subscriptionDueDate;
    if (!device.hasReminder || billingDate == null) return;

    final reminderDate = billingDate.subtract(
      Duration(days: _prefs.notificationLeadDays),
    );

    // Parse user preference time
    final timeParts = _prefs.notificationTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final scheduledDateTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      hour,
      minute,
    );

    // If the scheduled time is in the past, do not schedule (unless we want to support missed, handled separately)
    if (scheduledDateTime.isBefore(DateTime.now())) {
      return;
    }

    String body = '您的订阅 ${device.name} 即将到期';
    if (device.isAutoRenew) {
      final renewalPrice = device.renewalPrice ?? device.price;
      body +=
          '，将在 ${DateFormat('MM-dd').format(billingDate)} 自动续费 $renewalPrice 元';
    } else {
      body += '，将于 ${DateFormat('MM-dd').format(billingDate)} 到期';
    }

    await _notificationService.scheduleNotification(
      id: device.id, // Isar ID is int, suitable for notification ID
      title: '订阅提醒',
      body: body,
      scheduledDate: scheduledDateTime,
      payload: '/device/${device.id}',
    );
  }

  Future<void> cancelSubscriptionNotification(Device device) async {
    await _notificationService.cancelNotification(device.id);
  }

  Future<void> scheduleWarrantyNotification(Device device) async {
    if (device.warrantyEndDate == null) return;

    final warrantyDate = device.warrantyEndDate!;
    // Calculate notification date: 30 days before warranty expires
    final reminderDate = warrantyDate.subtract(const Duration(days: 30));

    // Parse user preference time
    final timeParts = _prefs.notificationTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final scheduledDateTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      hour,
      minute,
    );

    // If the scheduled time is in the past, do not schedule
    if (scheduledDateTime.isBefore(DateTime.now())) {
      return;
    }

    String body =
        '您的物品 ${device.name} 的保修即将在 ${DateFormat('MM-dd').format(warrantyDate)} 到期';

    await _notificationService.scheduleNotification(
      id: device.id + 100000, // Offset to avoid collision with subscription IDs
      title: '保修到期提醒',
      body: body,
      scheduledDate: scheduledDateTime,
      payload: '/device/${device.id}',
    );
  }

  Future<void> cancelWarrantyNotification(Device device) async {
    await _notificationService.cancelNotification(device.id + 100000);
  }

  /// Check for missed notifications on app start
  Future<void> checkMissedNotifications() async {
    final devices = await _deviceRepo.getAllDevices();
    final now = DateTime.now();

    // Parse user preference time
    final timeParts = _prefs.notificationTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    for (final device in devices) {
      final billingDate = device.subscriptionDueDate;
      if (!device.hasReminder || billingDate == null) continue;

      final reminderDate = billingDate.subtract(
        Duration(days: _prefs.notificationLeadDays),
      );

      // Determine the precise time the notification *should* have happened
      final scheduledDateTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        hour,
        minute,
      );

      // Condition 1: We are past the scheduled time
      if (now.isAfter(scheduledDateTime)) {
        // Condition 2: But we are still before the billing date (or on it, depending on preference)
        // Generally, we only want to remind if the billing hasn't happened yet or is happening today.
        // Let's say we remind until the billing date passes.
        if (now.isBefore(billingDate.add(const Duration(days: 1)))) {
          // Condition 3: Logic to prevent spamming every time app opens.
          // Requirement: "Max once per day"
          if (_prefs.hasCheckedToday(device.id)) continue;

          // Check if already active in tray (from OS schedule or previous check)
          final isActive = await _notificationService.isNotificationActive(
            device.id,
          );
          if (isActive) continue;

          // Robustness Requirement: "prevent user killing app... immediately send... check on app start"
          // Implementation: We will send an IMMEDIATE notification if we are in the [ReminderTime, BillingDate] window.
          // Optimization: We rely on the user dismissing it.

          await _notificationService.showNotification(
            id: device.id,
            title: '订阅提醒',
            body: '您的订阅 ${device.name} 即将到期',
            payload: '/device/${device.id}',
          );

          // Record that we notified today (manually)
          await _prefs.setCheckToday(device.id);
        }
      }
    }
  }

  Future<void> rescheduleAllNotifications() async {
    await _notificationService.cancelAllNotifications();
    final devices = await _deviceRepo.getAllDevices();
    for (final device in devices) {
      await scheduleSubscriptionNotification(device);
    }
  }

  /// Recursively renews the device until nextBillingDate is in the future.
  /// Returns true if any renewal happened.
  bool _processRenewal(Device device, DateTime targetDate) {
    final dueDate = device.subscriptionDueDate;
    if (dueDate == null || device.cycleType == null) {
      return false;
    }

    bool renewed = false;
    DateTime next = dueDate;

    // Safety break to prevent infinite loops if cycle is 0 or something weird
    int safetyCounter = 0;

    final targetDay = SubscriptionUtils.dateOnly(targetDate);
    while (SubscriptionUtils.dateOnly(next).isBefore(targetDay) &&
        safetyCounter < 1000) {
      final start = SubscriptionUtils.dateOnly(
        next,
      ).add(const Duration(days: 1));
      final end = SubscriptionUtils.advanceDueDate(
        next,
        device.cycleType!,
        calculationMode: device.cycleCalculationMode,
        cycleDays: device.cycleDays,
      );
      final renewalPrice = device.renewalPrice ?? device.price;

      final historyEntry = SubscriptionHistory()
        ..startDate = start
        ..endDate = end
        ..price = renewalPrice
        ..isAutoRenew = true
        ..cycleType = device.cycleType!
        ..cycleCalculationMode = device.cycleCalculationMode
        ..cycleDays = device.cycleDays
        ..recordDate = targetDate
        ..note = '自动续费';

      List<SubscriptionHistory> newHistory = List.from(device.history);
      newHistory.add(historyEntry);
      device.history = newHistory;

      // Accumulate price
      device.totalAccumulatedPrice += renewalPrice;

      // Calculate next date
      next = end;
      device.nextBillingDate = next;

      renewed = true;
      safetyCounter++;
    }

    return renewed;
  }

  /// Manually renews a subscription for a given number of cycles.
  Future<void> manualRenew(Device device, {int cycles = 1}) async {
    if (device.cycleType == null || device.cycleType == CycleType.oneTime) {
      return;
    }

    DateTime next = device.subscriptionDueDate ?? DateTime.now();

    for (int i = 0; i < cycles; i++) {
      final start = SubscriptionUtils.dateOnly(
        next,
      ).add(const Duration(days: 1));
      final end = SubscriptionUtils.advanceDueDate(
        next,
        device.cycleType!,
        calculationMode: device.cycleCalculationMode,
        cycleDays: device.cycleDays,
      );

      final historyEntry = SubscriptionHistory()
        ..startDate = start
        ..endDate = end
        ..price = device
            .price // Renewal price
        ..isAutoRenew =
            false // Manual renewal
        ..cycleType = device.cycleType!
        ..cycleCalculationMode = device.cycleCalculationMode
        ..cycleDays = device.cycleDays
        ..recordDate = DateTime.now();

      List<SubscriptionHistory> newHistory = List.from(device.history);
      newHistory.add(historyEntry);
      device.history = newHistory;

      device.totalAccumulatedPrice += device.price;
      next = end;
    }

    device.nextBillingDate = next;
    await _deviceRepo.updateDevice(device);
    // Use the updated date for scheduling
    await scheduleSubscriptionNotification(device);
  }
}
