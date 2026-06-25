import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownd/data/models/auth_user.dart';
import 'package:ownd/data/repositories/auth_repository.dart';
import 'package:ownd/data/services/preferences_service.dart';
import 'package:ownd/features/profile/account_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('opens account profile without provider lifecycle errors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          preferencesServiceProvider.overrideWithValue(
            PreferencesService(preferences),
          ),
        ],
        child: const MaterialApp(home: AccountProfileScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('账号资料'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  final _session = const AuthSession(
    token: 'token',
    user: AuthUser(id: 'user-1', email: 'lee@example.com', name: 'Lee'),
  );

  @override
  Future<AuthSession?> restoreSession() async => _session;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => _session;

  @override
  Future<AuthSession> signup({
    required String email,
    required String password,
    required String name,
    required String code,
  }) async => _session;

  @override
  Future<AuthSession> updatePreferences({
    required int notificationLeadDays,
    required String notificationTime,
  }) async => _session;

  @override
  Future<AuthSession> updateProfile({String? name, String? avatarPath}) async =>
      _session;

  @override
  Future<AuthSession> changeEmail({
    required String email,
    required String password,
    required String code,
  }) async => _session;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<AuthSession> uploadAvatar(String imagePath) async => _session;

  @override
  Future<AuthSession> deleteAvatar() async => _session;

  @override
  Future<void> sendVerificationCode(String email, {String? type}) async {}

  @override
  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String code,
  }) async {}

  @override
  Future<AuthUser> profile() async => _session.user;

  @override
  Future<void> logout() async {}
}
