import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/token_storage.dart';
import '../models/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthRepository(this._apiClient, this._tokenStorage);

  Future<AuthSession?> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      final user = await profile();
      return AuthSession(token: token, user: user);
    } catch (_) {
      await _tokenStorage.clearToken();
      return null;
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    return _persistLoginResult(data);
  }

  Future<AuthSession> signup({
    required String email,
    required String password,
    required String name,
    required String code,
  }) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      '/auth/signup',
      data: {'email': email, 'password': password, 'name': name, 'code': code},
    );

    return _persistLoginResult(data);
  }

  Future<AuthUser> profile() async {
    final data = await _apiClient.get<Map<String, dynamic>>('/auth/profile');
    return AuthUser.fromJson(data);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post<dynamic>('/auth/logout');
    } catch (_) {
      // ignore
    } finally {
      await _tokenStorage.clearToken();
    }
  }

  Future<void> sendVerificationCode(String email, {String? type}) async {
    await _apiClient.post<dynamic>(
      '/auth/send-code',
      data: {
        'email': email,
        if (type != null) 'type': type,
      },
    );
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String code,
  }) async {
    await _apiClient.post<dynamic>(
      '/auth/reset-password',
      data: {
        'email': email,
        'newPassword': newPassword,
        'code': code,
      },
    );
  }

  Future<AuthSession> _persistLoginResult(Map<String, dynamic> data) async {
    final token = (data['access_token'] ?? data['accessToken']) as String;
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    await _tokenStorage.saveToken(token);
    return AuthSession(token: token, user: user);
  }
}
