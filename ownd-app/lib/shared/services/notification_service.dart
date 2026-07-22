import 'dart:async';
import 'dart:io';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider((ref) => NotificationService());

class NotificationService {
  static const _subscriptionChannelId = 'subscription_reminders_v3';
  static const _subscriptionChannelName = '订阅提醒';
  static const _subscriptionChannelDescription = '即将到期的订阅提醒';
  static const _appUpdateChannelId = 'app_updates_v1';
  static const _appUpdateChannelName = '应用更新';
  static const _appUpdateChannelDescription = '应用更新下载进度';
  static const _appUpdateNotificationId = 20001;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Set<int> _shownNotificationIds = {};
  bool _isized = false;

  Future<void> init() async {
    if (_isized) return;

    tz.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

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
        unawaited(syncBadgeCount());
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
    await syncBadgeCount();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isized) await init();

    final badgeCount = notificationBadgeCountAfterShow(
      await _activeNotificationIds(),
      id,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetails(
        channelId: _subscriptionChannelId,
        channelName: _subscriptionChannelName,
        channelDescription: _subscriptionChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        badgeCount: badgeCount,
      ),
      payload: payload,
    );
    _shownNotificationIds.add(id);
    await _setBadgeCount(badgeCount);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isized) await init();

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _notificationDetails(
        channelId: _subscriptionChannelId,
        channelName: _subscriptionChannelName,
        channelDescription: _subscriptionChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        badgeCount: 1,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    if (!_isized) await init();
    await _notificationsPlugin.cancel(id);
    _shownNotificationIds.remove(id);
    final badgeCount = notificationBadgeCountAfterCancel(
      await _activeNotificationIds(),
      id,
    );
    await _setBadgeCount(badgeCount);
  }

  Future<void> cancelAllNotifications() async {
    if (!_isized) await init();
    await _notificationsPlugin.cancelAll();
    _shownNotificationIds.clear();
    await _setBadgeCount(0);
  }

  Future<void> showAppUpdateDownloadProgress(int progress) async {
    if (!_isized) await init();

    final safeProgress = progress.clamp(0, 100).toInt();
    final badgeCount = notificationBadgeCountAfterShow(
      await _activeNotificationIds(),
      _appUpdateNotificationId,
    );

    await _notificationsPlugin.show(
      _appUpdateNotificationId,
      '正在下载更新',
      '$safeProgress%',
      _notificationDetails(
        channelId: _appUpdateChannelId,
        channelName: _appUpdateChannelName,
        channelDescription: _appUpdateChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        ongoing: safeProgress < 100,
        showProgress: true,
        maxProgress: 100,
        progress: safeProgress,
        badgeCount: badgeCount,
      ),
    );
    _shownNotificationIds.add(_appUpdateNotificationId);
    await _setBadgeCount(badgeCount);
  }

  Future<void> showAppUpdateDownloadComplete() async {
    if (!_isized) await init();

    final badgeCount = notificationBadgeCountAfterShow(
      await _activeNotificationIds(),
      _appUpdateNotificationId,
    );

    await _notificationsPlugin.show(
      _appUpdateNotificationId,
      '更新包已下载',
      '请按系统提示完成安装',
      _notificationDetails(
        channelId: _appUpdateChannelId,
        channelName: _appUpdateChannelName,
        channelDescription: _appUpdateChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        badgeCount: badgeCount,
      ),
    );
    _shownNotificationIds.add(_appUpdateNotificationId);
    await _setBadgeCount(badgeCount);
  }

  Future<void> showAppUpdateDownloadFailed() async {
    if (!_isized) await init();

    final badgeCount = notificationBadgeCountAfterShow(
      await _activeNotificationIds(),
      _appUpdateNotificationId,
    );

    await _notificationsPlugin.show(
      _appUpdateNotificationId,
      '更新包下载失败',
      '请稍后重试',
      _notificationDetails(
        channelId: _appUpdateChannelId,
        channelName: _appUpdateChannelName,
        channelDescription: _appUpdateChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        onlyAlertOnce: true,
        badgeCount: badgeCount,
      ),
    );
    _shownNotificationIds.add(_appUpdateNotificationId);
    await _setBadgeCount(badgeCount);
  }

  Future<bool> isNotificationActive(int id) async {
    if (!_isized) await init();
    // Android only for now, iOS doesn't easily support getting active without heavy lifting or it's similar
    // flutter_local_notifications support:
    final activeNotifications = await _notificationsPlugin
        .getActiveNotifications();
    return activeNotifications.any((n) => n.id == id);
  }

  Future<void> syncBadgeCount() async {
    if (!_isized) return;
    await _setBadgeCount((await _activeNotificationIds()).length);
  }

  Future<Set<int>> _activeNotificationIds() async {
    try {
      final ids = (await _notificationsPlugin.getActiveNotifications())
          .map((notification) => notification.id)
          .whereType<int>()
          .toSet();
      _shownNotificationIds
        ..clear()
        ..addAll(ids);
    } catch (_) {
      // Some platforms cannot report active notifications.
    }
    return {..._shownNotificationIds};
  }

  Future<void> _setBadgeCount(int count) async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) return;

    try {
      if (await AppBadgePlus.isSupported()) {
        await AppBadgePlus.updateBadge(count);
      }
    } catch (_) {
      // Badge support is launcher/platform dependent.
    }
  }

  NotificationDetails _notificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required Importance importance,
    required Priority priority,
    required bool playSound,
    required bool enableVibration,
    bool onlyAlertOnce = false,
    bool ongoing = false,
    bool showProgress = false,
    int maxProgress = 0,
    int progress = 0,
    int? badgeCount,
  }) {
    final darwinDetails = DarwinNotificationDetails(
      presentBadge: true,
      badgeNumber: badgeCount,
    );

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: priority,
        enableVibration: enableVibration,
        playSound: playSound,
        ticker: channelName,
        onlyAlertOnce: onlyAlertOnce,
        ongoing: ongoing,
        showProgress: showProgress,
        maxProgress: maxProgress,
        progress: progress,
        number: badgeCount,
      ),
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  @visibleForTesting
  static int notificationBadgeCountAfterShow(Iterable<int> activeIds, int id) {
    return ({...activeIds, id}).length;
  }

  @visibleForTesting
  static int notificationBadgeCountAfterCancel(
    Iterable<int> activeIds,
    int id,
  ) {
    return ({...activeIds}..remove(id)).length;
  }
}
