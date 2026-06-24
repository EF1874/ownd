import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/category_repository.dart';
import '../../data/models/auth_user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/platform_repository.dart';
import '../../data/services/preferences_service.dart';
import '../home/home_devices_provider.dart';
import '../home/home_screen.dart';
import '../navigation/navigation_provider.dart';
import '../timeline/logic/timeline_provider.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
      return AuthController(ref, ref.watch(authRepositoryProvider));
    });

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  final Ref _ref;
  final AuthRepository _repository;

  AuthController(this._ref, this._repository)
    : super(const AsyncValue.loading()) {
    restore();
  }

  Future<void> restore() async {
    state = const AsyncValue.loading();
    final session = await _repository.restoreSession();
    await _syncPreferences(session);
    state = AsyncValue.data(session);
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard<AuthSession?>(
      () => _repository.login(email: email, password: password),
    );
    if (result.hasValue) {
      await _syncPreferences(result.value);
      _invalidateUserData();
    }
    state = result;
  }

  Future<void> signup({
    required String email,
    required String password,
    required String name,
    required String code,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard<AuthSession?>(
      () => _repository.signup(
        email: email,
        password: password,
        name: name,
        code: code,
      ),
    );
    if (result.hasValue) {
      await _syncPreferences(result.value);
      _invalidateUserData();
    }
    state = result;
  }

  Future<void> updatePreferences({
    required int notificationLeadDays,
    required String notificationTime,
  }) async {
    final session = await _repository.updatePreferences(
      notificationLeadDays: notificationLeadDays,
      notificationTime: notificationTime,
    );
    await _syncPreferences(session);
    state = AsyncValue.data(session);
  }

  Future<void> logout() async {
    await _repository.logout();
    _invalidateUserData();
    state = const AsyncValue.data(null);
  }

  void _invalidateUserData() {
    _ref.invalidate(deviceListProvider);
    _ref.invalidate(homeSummaryProvider);
    _ref.invalidate(deviceRepositoryProvider);
    _ref.invalidate(deviceDataSourceProvider);

    _ref.invalidate(categoryTreeProvider);
    _ref.invalidate(categoryRepositoryProvider);
    _ref.invalidate(categoryDataSourceProvider);

    _ref.invalidate(platformsProvider);
    _ref.invalidate(platformRepositoryProvider);

    _ref.invalidate(timelineEventsProvider);
    _ref.read(timelineFilterProvider.notifier).state = {};
    _ref.read(timelineTagFilterProvider.notifier).state = {};
    _ref.read(bottomNavBarVisibleProvider.notifier).state = true;
  }

  Future<void> _syncPreferences(AuthSession? session) async {
    if (session == null) return;
    final prefs = _ref.read(preferencesServiceProvider);
    await prefs.setNotificationLeadDays(session.user.notificationLeadDays);
    await prefs.setNotificationTime(session.user.notificationTime);
  }
}
