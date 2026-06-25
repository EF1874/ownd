import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

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
      final refreshedToken = await _tokenStorage.readToken();
      return AuthSession(token: refreshedToken ?? token, user: user);
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
    final userData = data['user'];
    if (userData is Map<String, dynamic>) {
      final token = (data['access_token'] ?? data['accessToken']) as String?;
      if (token != null && token.isNotEmpty) {
        await _tokenStorage.saveToken(token);
      }
      return AuthUser.fromJson(userData);
    }
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

  Future<AuthSession> updatePreferences({
    required int notificationLeadDays,
    required String notificationTime,
  }) async {
    final data = await _apiClient.patch<Map<String, dynamic>>(
      '/auth/profile',
      data: {
        'notificationLeadDays': notificationLeadDays,
        'notificationTime': notificationTime,
      },
    );

    return _persistLoginResult(data);
  }

  Future<AuthSession> updateProfile({String? name, String? avatarPath}) async {
    final data = await _apiClient.patch<Map<String, dynamic>>(
      '/auth/profile',
      data: {
        if (name != null) 'name': name,
        if (avatarPath != null) 'avatarPath': avatarPath,
      },
    );

    return _persistLoginResult(data);
  }

  Future<AuthSession> changeEmail({
    required String email,
    required String password,
    required String code,
  }) async {
    final data = await _apiClient.patch<Map<String, dynamic>>(
      '/auth/profile/email',
      data: {'email': email, 'password': password, 'code': code},
    );

    return _persistLoginResult(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.patch<dynamic>(
      '/auth/profile/password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<AuthSession> uploadAvatar(String imagePath) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      '/auth/profile/avatar',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imagePath,
          filename: p.basename(imagePath),
          contentType: await _imageContentType(imagePath),
        ),
      }),
    );

    return _persistLoginResult(data);
  }

  Future<AuthSession> deleteAvatar() async {
    final data = await _apiClient.delete<Map<String, dynamic>>(
      '/auth/profile/avatar',
    );

    return _persistLoginResult(data);
  }

  Future<void> sendVerificationCode(String email, {String? type}) async {
    await _apiClient.post<dynamic>(
      '/auth/send-code',
      data: {'email': email, if (type != null) 'type': type},
    );
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
    required String code,
  }) async {
    await _apiClient.post<dynamic>(
      '/auth/reset-password',
      data: {'email': email, 'newPassword': newPassword, 'code': code},
    );
  }

  Future<AuthSession> _persistLoginResult(Map<String, dynamic> data) async {
    final token = (data['access_token'] ?? data['accessToken']) as String;
    final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    await _tokenStorage.saveToken(token);
    return AuthSession(token: token, user: user);
  }

  Future<DioMediaType> _imageContentType(String imagePath) async {
    final bytes = await File(imagePath).openRead(0, 12).first;
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return DioMediaType.parse('image/png');
    }
    return DioMediaType.parse('image/jpeg');
  }
}
