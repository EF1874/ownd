import 'package:flutter_test/flutter_test.dart';
import 'package:ownd/data/datasource/device_datasource.dart';
import 'package:ownd/data/models/device.dart';
import 'package:ownd/data/repositories/device_repository.dart';
import 'package:ownd/data/services/preferences_service.dart';
import 'package:ownd/shared/services/notification_service.dart';
import 'package:ownd/shared/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('preferences preserve expiry-day reminders', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = PreferencesService(
      await SharedPreferences.getInstance(),
    );

    await preferences.setNotificationLeadDays(0);

    expect(preferences.notificationLeadDays, 0);
  });

  test('expiry-day reminders use the due date and configured time', () async {
    SharedPreferences.setMockInitialValues({
      'notification_lead_days': 0,
      'notification_time': '08:00',
    });
    final dueDate = DateTime.now().add(const Duration(days: 2));
    final device = Device()
      ..id = 42
      ..name = '测试订阅'
      ..hasReminder = true
      ..nextBillingDate = dueDate;
    final notifications = _RecordingNotificationService();
    final service = SubscriptionService(
      DeviceRepository(_DeviceDataSource([device])),
      notifications,
      PreferencesService(await SharedPreferences.getInstance()),
    );

    await service.scheduleSubscriptionNotification(device);

    final scheduled = notifications.scheduledDates.single;
    expect(scheduled.year, dueDate.year);
    expect(scheduled.month, dueDate.month);
    expect(scheduled.day, dueDate.day);
    expect((scheduled.hour, scheduled.minute), (8, 0));
  });

  test('missed expiry-day reminder is shown at most once that day', () async {
    SharedPreferences.setMockInitialValues({
      'notification_lead_days': 0,
      'notification_time': '00:00',
    });
    final now = DateTime.now();
    final device = Device()
      ..id = 42
      ..name = '测试订阅'
      ..hasReminder = true
      ..nextBillingDate = DateTime(now.year, now.month, now.day);
    final notifications = _RecordingNotificationService();
    final service = SubscriptionService(
      DeviceRepository(_DeviceDataSource([device])),
      notifications,
      PreferencesService(await SharedPreferences.getInstance()),
    );

    await service.checkMissedNotifications();
    await service.checkMissedNotifications();

    expect(notifications.shownIds, [42]);
  });

  test(
    'startup restores future subscription and warranty notifications',
    () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final device = Device()
        ..id = 42
        ..name = '测试订阅'
        ..hasReminder = true
        ..nextBillingDate = now.add(const Duration(days: 30))
        ..warrantyEndDate = now.add(const Duration(days: 60));
      final notifications = _RecordingNotificationService();
      final service = SubscriptionService(
        DeviceRepository(_DeviceDataSource([device])),
        notifications,
        PreferencesService(await SharedPreferences.getInstance()),
      );

      await service.checkStartupSubscriptions();

      expect(notifications.scheduledIds, [42, 100042]);
    },
  );

  test(
    'rescheduling restores subscription and warranty notifications',
    () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now();
      final device = Device()
        ..id = 42
        ..name = '测试订阅'
        ..hasReminder = true
        ..nextBillingDate = now.add(const Duration(days: 30))
        ..warrantyEndDate = now.add(const Duration(days: 60));
      final notifications = _RecordingNotificationService();
      final service = SubscriptionService(
        DeviceRepository(_DeviceDataSource([device])),
        notifications,
        PreferencesService(await SharedPreferences.getInstance()),
      );

      await service.rescheduleAllNotifications();

      expect(notifications.cancelAllCalls, 1);
      expect(notifications.scheduledIds, [42, 100042]);
    },
  );
}

class _RecordingNotificationService extends NotificationService {
  final scheduledIds = <int>[];
  final scheduledDates = <DateTime>[];
  final shownIds = <int>[];
  var cancelAllCalls = 0;

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    scheduledIds.add(id);
    scheduledDates.add(scheduledDate);
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    shownIds.add(id);
  }

  @override
  Future<bool> isNotificationActive(int id) async => false;

  @override
  Future<void> cancelAllNotifications() async {
    cancelAllCalls++;
  }
}

class _DeviceDataSource implements DeviceDataSource {
  _DeviceDataSource(this.devices);

  final List<Device> devices;

  @override
  Future<List<Device>> getAll() async => devices;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
