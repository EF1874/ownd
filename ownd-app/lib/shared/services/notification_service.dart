import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  static const _subscriptionChannelId = 'subscription_reminders_v3';
  static const _subscriptionChannelName = '订阅提醒';
  static const _subscriptionChannelDescription = '即将到期或续费的订阅提醒';
  static const _appUpdateChannelId = 'app_updates_v1';
  static const _appUpdateChannelName = '应用更新';
  static const _appUpdateChannelDescription = '应用更新下载进度';
  static const _appUpdateNotificationId = 20001;

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
      final androidNotifications = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await androidNotifications?.createNotificationChannel(
        const AndroidNotificationChannel(
          _subscriptionChannelId,
          _subscriptionChannelName,
          description: _subscriptionChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      await androidNotifications?.createNotificationChannel(
        const AndroidNotificationChannel(
          _appUpdateChannelId,
          _appUpdateChannelName,
          description: _appUpdateChannelDescription,
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );
      await androidNotifications?.requestNotificationsPermission();
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
          _subscriptionChannelId,
          _subscriptionChannelName,
          channelDescription: _subscriptionChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
          ticker: _subscriptionChannelName,
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
          _subscriptionChannelId,
          _subscriptionChannelName,
          channelDescription: _subscriptionChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          enableVibration: true,
          playSound: true,
          ticker: _subscriptionChannelName,
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

  Future<void> showAppUpdateDownloadProgress(int progress) async {
    if (!_isized) await init();

    final safeProgress = progress.clamp(0, 100).toInt();
    final androidDetails = AndroidNotificationDetails(
      _appUpdateChannelId,
      _appUpdateChannelName,
      channelDescription: _appUpdateChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      ongoing: safeProgress < 100,
      showProgress: true,
      maxProgress: 100,
      progress: safeProgress,
      playSound: false,
      enableVibration: false,
    );

    await _notificationsPlugin.show(
      _appUpdateNotificationId,
      '正在下载更新',
      '$safeProgress%',
      NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showAppUpdateDownloadComplete() async {
    if (!_isized) await init();

    const androidDetails = AndroidNotificationDetails(
      _appUpdateChannelId,
      _appUpdateChannelName,
      channelDescription: _appUpdateChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
    );

    await _notificationsPlugin.show(
      _appUpdateNotificationId,
      '更新包已下载',
      '请按系统提示完成安装',
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> showAppUpdateDownloadFailed() async {
    if (!_isized) await init();

    const androidDetails = AndroidNotificationDetails(
      _appUpdateChannelId,
      _appUpdateChannelName,
      channelDescription: _appUpdateChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
    );

    await _notificationsPlugin.show(
      _appUpdateNotificationId,
      '更新包下载失败',
      '请稍后重试',
      const NotificationDetails(android: androidDetails),
    );
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
