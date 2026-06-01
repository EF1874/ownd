import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isized = false;

  Future<void> init() async {
    if (_isized) return;

    tz.initializeTimeZones();

    // Android Settings
    // Ensure you have a drawable/mipmap icon named 'ic_launcher' or 'app_icon'
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Settings
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap logic here
      },
    );

    // Request Permissions
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    _isized = true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isized) await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'subscription_reminders_v2', // Changed ID
          '订阅提醒', // channel Name
          channelDescription: '即将到期或续费的订阅提醒',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
          ticker: '订阅提醒',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isized) await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'subscription_reminders_v2', // Changed ID to force update
          '订阅提醒',
          channelDescription: '即将到期或续费的订阅提醒',
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
          ticker: '订阅提醒', // Accessibility
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_isized) await init();
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    if (!_isized) await init();
    await _notificationsPlugin.cancelAll();
  }

  Future<bool> isNotificationActive(int id) async {
    if (!_isized) await init();
    // Android only for now, iOS doesn't easily support getting active without heavy lifting or it's similar
    // flutter_local_notifications support:
    final activeNotifications = await _notificationsPlugin
        .getActiveNotifications();
    return activeNotifications.any((n) => n.id == id);
  }
}
