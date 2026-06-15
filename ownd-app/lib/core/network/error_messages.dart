import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import 'api_exception.dart';

String userErrorMessage(Object error, {String fallback = '操作失败，请稍后重试'}) {
  if (error is ApiException) {
    return _cleanMessage(error.message, fallback: fallback);
  }

  if (error is DioException) {
    return friendlyDioErrorMessage(error);
  }

  if (error is PlatformException) {
    return _cleanMessage(error.message ?? '', fallback: fallback);
  }

  final raw = error.toString();
  final lower = raw.toLowerCase();

  if (_containsAny(lower, const [
    'econnrefused',
    'connection refused',
    'actively refused',
    'connection error',
    'socketexception',
  ])) {
    return '暂时无法连接服务器，请稍后重试';
  }

  if (_containsAny(lower, const [
    'connection timed out',
    'timeout',
    'timed out',
  ])) {
    return '网络连接超时，请检查网络后重试';
  }

  if (_containsAny(lower, const [
    'failed host lookup',
    'no address associated',
    'network is unreachable',
  ])) {
    return '网络不可用，请检查网络连接';
  }

  if (_containsAny(lower, const [
    'permission denied',
    'request_install_packages',
    'unknown app',
  ])) {
    return '需要开启安装权限后才能继续';
  }

  return _cleanMessage(raw, fallback: fallback);
}

String friendlyDioErrorMessage(DioException error) {
  final serverMessage = _serverMessage(error.response?.data);
  if (serverMessage != null) {
    return serverMessage;
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return '网络连接超时，请稍后重试';
    case DioExceptionType.connectionError:
      return '暂时无法连接服务器，请稍后重试';
    case DioExceptionType.badCertificate:
      return '网络安全校验失败，请稍后重试';
    case DioExceptionType.cancel:
      return '请求已取消';
    case DioExceptionType.badResponse:
      return _httpStatusMessage(error.response?.statusCode);
    case DioExceptionType.unknown:
      return userErrorMessage(error.message ?? '', fallback: '网络请求失败，请稍后重试');
  }
}

String? _serverMessage(Object? data) {
  if (data is! Map<String, dynamic>) {
    return null;
  }

  final rawMessage = data['msg'] ?? data['message'];
  if (rawMessage is String && rawMessage.trim().isNotEmpty) {
    return _cleanMessage(rawMessage, fallback: '提交的信息有误，请检查后重试');
  }

  if (rawMessage is List && rawMessage.isNotEmpty) {
    final messages = rawMessage
        .map((message) => _cleanMessage('$message', fallback: ''))
        .where((message) => message.isNotEmpty)
        .join('，');
    return messages.isEmpty ? '提交的信息有误，请检查后重试' : messages;
  }

  return null;
}

String _httpStatusMessage(int? statusCode) {
  switch (statusCode) {
    case 400:
      return '提交的信息有误，请检查后重试';
    case 401:
      return '登录状态已失效，请重新登录';
    case 403:
      return '没有权限执行此操作';
    case 404:
      return '请求的内容不存在或已被删除';
    case 408:
      return '请求超时，请稍后重试';
    case 409:
      return '数据已发生变化，请刷新后重试';
    case 413:
      return '上传内容过大，请压缩后重试';
    case 429:
      return '操作太频繁，请稍后再试';
    case 500:
    case 502:
    case 503:
    case 504:
      return '服务器暂时不可用，请稍后重试';
    default:
      return '请求失败，请稍后重试';
  }
}

String _cleanMessage(String message, {required String fallback}) {
  var cleaned = message
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^ApiException:\s*'), '')
      .replaceFirst(RegExp(r'^DioException \[.*?\]:\s*'), '')
      .trim();

  if (cleaned.isEmpty) {
    return fallback;
  }

  final lower = cleaned.toLowerCase();
  if (_containsAny(lower, const [
    'xmlhttprequest',
    'socketexception',
    'httpexception',
    'dioexception',
    'stacktrace',
    'errno',
    '127.0.0.1',
    'localhost',
  ])) {
    return fallback;
  }

  if (_containsAny(lower, const [
    'bad request',
    'validation failed',
    'must be',
    'should not',
    'is not allowed',
    'is required',
    'cannot ',
    'invalid input',
  ])) {
    return fallback;
  }

  return cleaned;
}

bool _containsAny(String value, List<String> patterns) {
  return patterns.any(value.contains);
}
