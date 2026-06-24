import '../../core/config/app_config.dart';

bool isRemoteImagePath(String path) {
  return path.startsWith('/ownd-items/') ||
      RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(path);
}

String imageUrlForPath(String path) {
  if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(path)) return path;

  final fileName = path.split('/').where((part) => part.isNotEmpty).last;
  final baseUrl = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
  return '$baseUrl/items/images/${Uri.encodeComponent(fileName)}';
}
