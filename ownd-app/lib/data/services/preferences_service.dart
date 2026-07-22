import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw UnimplementedError();
});

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static const _keyIsGridView = 'is_grid_view';
  static const _keySortBy = 'sort_by';
  static const _keyExpiringSoonOnly = 'expiring_soon_only';

  bool get isGridView => _prefs.getBool(_keyIsGridView) ?? false;

  Future<void> setGridView(bool value) async {
    await _prefs.setBool(_keyIsGridView, value);
  }

  String get sortBy => _prefs.getString(_keySortBy) ?? 'date_desc';

  Future<void> setSortBy(String value) async {
    await _prefs.setString(_keySortBy, value);
  }

  bool get expiringSoonOnly => _prefs.getBool(_keyExpiringSoonOnly) ?? false;

  Future<void> setExpiringSoonOnly(bool value) async {
    await _prefs.setBool(_keyExpiringSoonOnly, value);
  }

  static const _keyThemeMode = 'theme_mode';

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';

  Future<void> setThemeMode(String value) async {
    await _prefs.setString(_keyThemeMode, value);
  }

  static const _keyNotificationTime = 'notification_time';
  static const _keyNotificationLeadDays = 'notification_lead_days';
  static const _keyLastAppUpdateAutoCheck = 'last_app_update_auto_check';
  static const notificationLeadDayOptions = [0, 1, 3, 7, 14, 30];

  /// Format: "HH:mm" 24-hour format
  String get notificationTime =>
      _prefs.getString(_keyNotificationTime) ?? '08:00';

  Future<void> setNotificationTime(String value) async {
    await _prefs.setString(_keyNotificationTime, value);
  }

  int get notificationLeadDays {
    final days = _prefs.getInt(_keyNotificationLeadDays) ?? 3;
    return notificationLeadDayOptions.contains(days) ? days : 3;
  }

  Future<void> setNotificationLeadDays(int value) async {
    final days = notificationLeadDayOptions.contains(value) ? value : 3;
    await _prefs.setInt(_keyNotificationLeadDays, days);
  }

  bool hasCheckedAppUpdateToday() {
    final timestamp = _prefs.getInt(_keyLastAppUpdateAutoCheck);
    if (timestamp == null) return false;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> setAppUpdateCheckedToday() async {
    await _prefs.setInt(
      _keyLastAppUpdateAutoCheck,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Helper for manual check throttling
  String _getKeyLastManualCheck(int deviceId) => 'last_manual_check_$deviceId';

  bool hasCheckedToday(int deviceId) {
    final timestamp = _prefs.getInt(_getKeyLastManualCheck(deviceId));
    if (timestamp == null) return false;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> setCheckToday(int deviceId) async {
    await _prefs.setInt(
      _getKeyLastManualCheck(deviceId),
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
