import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

final apiBaseUrlProvider = Provider<String>((ref) {
  return AppConfig.apiBaseUrl;
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ref.watch(apiBaseUrlProvider),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  // 针对公网 IP 自签名 HTTPS，配置客户端允许自签名证书
  if (dio.httpClientAdapter is IOHttpClientAdapter) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(tokenStorageProvider).readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint(
            'API error: ${error.requestOptions.path} ${error.message}',
          );
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

class ApiClient {
  final Dio _dio;

  ApiClient(this._dio);

  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) {
    return _request<T>(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<T> post<T>(String path, {Object? data}) {
    return _request<T>(() => _dio.post(path, data: data));
  }

  Future<T> patch<T>(String path, {Object? data}) {
    return _request<T>(() => _dio.patch(path, data: data));
  }

  Future<T> delete<T>(String path) {
    return _request<T>(() => _dio.delete(path));
  }

  Future<T> _request<T>(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final body = response.data;

      if (body is Map<String, dynamic> && body.containsKey('data')) {
        return body['data'] as T;
      }

      return body as T;
    } on DioException catch (error) {
      final data = error.response?.data;
      String message = error.message ?? '网络请求失败';

      if (data is Map<String, dynamic>) {
        final rawMessage = data['msg'] ?? data['message'];
        if (rawMessage is String && rawMessage.isNotEmpty) {
          message = rawMessage;
        } else if (rawMessage is List && rawMessage.isNotEmpty) {
          message = rawMessage.join(', ');
        }
      }

      throw ApiException(message, statusCode: error.response?.statusCode);
    } on TypeError {
      throw const ApiException('接口响应格式不符合预期');
    }
  }
}
