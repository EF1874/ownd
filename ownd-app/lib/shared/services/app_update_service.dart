import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_client.dart';
import 'notification_service.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(
    apiClient: ref.watch(apiClientProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.platform,
    required this.version,
    required this.versionCode,
    required this.forceUpdate,
    required this.artifacts,
    required this.selectedArtifact,
    required this.releaseNotes,
    this.minSupportedVersion,
    this.title,
    this.publishedAt,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    final artifacts = _artifactsFromJson(json);
    final selectedArtifact =
        artifacts
            .where((artifact) => artifact.abi == 'universal')
            .firstOrNull ??
        artifacts.first;

    return AppUpdateInfo(
      platform: json['platform'] as String,
      version: json['version'] as String,
      versionCode: json['versionCode'] as int,
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      artifacts: artifacts,
      selectedArtifact: selectedArtifact,
      releaseNotes:
          (json['releaseNotes'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<String>()
              .toList(),
      minSupportedVersion: json['minSupportedVersion'] as String?,
      title: json['title'] as String?,
      publishedAt: json['publishedAt'] as String?,
    );
  }

  static List<AppUpdateArtifact> _artifactsFromJson(Map<String, dynamic> json) {
    final artifactsJson = json['artifacts'];
    final fallbackVersionCode = json['versionCode'] as int;
    if (artifactsJson is List && artifactsJson.isNotEmpty) {
      return artifactsJson
          .whereType<Map<String, dynamic>>()
          .map(
            (artifact) => AppUpdateArtifact.fromJson(
              artifact,
              fallbackVersionCode: fallbackVersionCode,
            ),
          )
          .toList();
    }

    return [
      AppUpdateArtifact(
        abi: 'universal',
        apkUrl: json['apkUrl'] as String,
        versionCode: fallbackVersionCode,
        apkSizeBytes: json['apkSizeBytes'] as int,
        sha256: json['sha256'] as String,
      ),
    ];
  }

  final String platform;
  final String version;
  final int versionCode;
  final bool forceUpdate;
  final List<AppUpdateArtifact> artifacts;
  final AppUpdateArtifact selectedArtifact;
  final List<String> releaseNotes;
  final String? minSupportedVersion;
  final String? title;
  final String? publishedAt;

  String get apkUrl => selectedArtifact.apkUrl;

  int get apkSizeBytes => selectedArtifact.apkSizeBytes;

  int get selectedVersionCode => selectedArtifact.versionCode;

  String get sha256 => selectedArtifact.sha256;

  AppUpdateInfo selectArtifact(List<String> supportedAbis) {
    for (final abi in supportedAbis) {
      final matched = artifacts
          .where((artifact) => artifact.abi == abi)
          .firstOrNull;
      if (matched != null) {
        return _copyWithSelectedArtifact(matched);
      }
    }

    final universal = artifacts
        .where((artifact) => artifact.abi == 'universal')
        .firstOrNull;
    return _copyWithSelectedArtifact(universal ?? artifacts.first);
  }

  AppUpdateInfo _copyWithSelectedArtifact(AppUpdateArtifact artifact) {
    return AppUpdateInfo(
      platform: platform,
      version: version,
      versionCode: versionCode,
      forceUpdate: forceUpdate,
      artifacts: artifacts,
      selectedArtifact: artifact,
      releaseNotes: releaseNotes,
      minSupportedVersion: minSupportedVersion,
      title: title,
      publishedAt: publishedAt,
    );
  }
}

class AppUpdateArtifact {
  const AppUpdateArtifact({
    required this.abi,
    required this.apkUrl,
    required this.versionCode,
    required this.apkSizeBytes,
    required this.sha256,
  });

  factory AppUpdateArtifact.fromJson(
    Map<String, dynamic> json, {
    required int fallbackVersionCode,
  }) {
    return AppUpdateArtifact(
      abi: json['abi'] as String,
      apkUrl: json['apkUrl'] as String,
      versionCode: json['versionCode'] as int? ?? fallbackVersionCode,
      apkSizeBytes: json['apkSizeBytes'] as int,
      sha256: json['sha256'] as String,
    );
  }

  final String abi;
  final String apkUrl;
  final int versionCode;
  final int apkSizeBytes;
  final String sha256;
}

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latest,
    required this.hasUpdate,
  });

  final String currentVersion;
  final int currentBuildNumber;
  final AppUpdateInfo latest;
  final bool hasUpdate;
}

class AppUpdateService {
  const AppUpdateService({
    required ApiClient apiClient,
    required NotificationService notificationService,
  }) : _apiClient = apiClient,
       _notificationService = notificationService;

  static const _installPermissionChannel = MethodChannel(
    'com.antigravity.ownd/install_permission',
  );

  final ApiClient _apiClient;
  final NotificationService _notificationService;

  Dio get _downloadDio => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  Future<AppUpdateCheckResult> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final latestJson = await _apiClient.get<Map<String, dynamic>>(
      '/app-updates/latest',
      queryParameters: {'platform': 'android'},
    );
    final latest = AppUpdateInfo.fromJson(
      latestJson,
    ).selectArtifact(await _supportedAbis());
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final versionCompare = _compareVersions(
      latest.version,
      packageInfo.version,
    );
    final hasUpdate =
        versionCompare > 0 ||
        (versionCompare == 0 &&
            currentBuildNumber > 0 &&
            latest.selectedVersionCode > currentBuildNumber);
    await _cleanupCachedApks(keep: hasUpdate ? latest : null);

    return AppUpdateCheckResult(
      currentVersion: packageInfo.version,
      currentBuildNumber: currentBuildNumber,
      latest: latest,
      hasUpdate: hasUpdate,
    );
  }

  Future<void> downloadAndInstall(
    AppUpdateInfo update, {
    void Function(double progress)? onProgress,
  }) async {
    final apkFile = await _getOrDownloadApk(update, onProgress: onProgress);
    if (Platform.isAndroid) {
      await _ensureInstallPermission();
      final installerOpened = await _installApk(apkFile);
      if (!installerOpened) {
        throw Exception('请打开“允许安装未知应用”权限后返回继续安装');
      }
      return;
    }

    final result = await OpenFile.open(
      apkFile.path,
      type: 'application/vnd.android.package-archive',
    );

    if (result.type != ResultType.done) {
      if (Platform.isAndroid && _isInstallPermissionError(result.message)) {
        await _openInstallPermissionSettings();
      }
      throw Exception(_installErrorMessage(result.message));
    }
  }

  Future<bool> isUpdateCached(AppUpdateInfo update) async {
    return await _getCachedApkIfValid(update) != null;
  }

  Future<File> _getOrDownloadApk(
    AppUpdateInfo update, {
    void Function(double progress)? onProgress,
  }) async {
    final cachedFile = await _getCachedApkIfValid(update);
    if (cachedFile != null) {
      onProgress?.call(1);
      return cachedFile;
    }

    final targetFile = await _cachedApkFile(update);
    if (Platform.isAndroid) {
      return _downloadApkWithNotification(
        update,
        targetFile: targetFile,
        onProgress: onProgress,
      );
    }

    return _downloadApk(update, targetFile: targetFile, onProgress: onProgress);
  }

  Future<File?> _getCachedApkIfValid(AppUpdateInfo update) async {
    final cachedFile = await _cachedApkFile(update);
    if (!await cachedFile.exists()) {
      return null;
    }

    try {
      await _verifySha256(cachedFile, update.sha256);
      return cachedFile;
    } catch (_) {
      try {
        await cachedFile.delete();
      } catch (_) {
        // Ignore stale cache cleanup errors and attempt a fresh download.
      }
      return null;
    }
  }

  Future<File> _downloadApkWithNotification(
    AppUpdateInfo update, {
    required File targetFile,
    void Function(double progress)? onProgress,
  }) async {
    var lastNotifiedProgress = -1;
    try {
      await _notificationService.showAppUpdateDownloadProgress(0);
      final apkFile = await _downloadApk(
        update,
        targetFile: targetFile,
        onProgress: (progress) {
          onProgress?.call(progress);
          final percent = (progress * 100).clamp(0, 100).round();
          if (percent == 100 || percent >= lastNotifiedProgress + 5) {
            lastNotifiedProgress = percent;
            unawaited(
              _notificationService.showAppUpdateDownloadProgress(percent),
            );
          }
        },
      );
      await _notificationService.showAppUpdateDownloadComplete();
      return apkFile;
    } catch (_) {
      await _notificationService.showAppUpdateDownloadFailed();
      rethrow;
    }
  }

  Future<File> _downloadApk(
    AppUpdateInfo update, {
    required File targetFile,
    void Function(double progress)? onProgress,
  }) async {
    await targetFile.parent.create(recursive: true);
    final downloadingFile = File('${targetFile.path}.download');

    await _downloadDio.download(
      update.apkUrl,
      downloadingFile.path,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        if (total <= 0) return;
        onProgress?.call(received / total);
      },
    );

    await _verifySha256(downloadingFile, update.sha256);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    return downloadingFile.rename(targetFile.path);
  }

  Future<File> _cachedApkFile(AppUpdateInfo update) async {
    final updateDir = await _updatesDirectory();
    final shaPrefix = update.sha256.length >= 12
        ? update.sha256.substring(0, 12)
        : update.sha256;
    return File(
      p.join(
        updateDir.path,
        'ownd-${update.selectedVersionCode}-$shaPrefix.apk',
      ),
    );
  }

  Future<Directory> _updatesDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory(p.join(appDir.path, 'updates'));
  }

  Future<void> _cleanupCachedApks({AppUpdateInfo? keep}) async {
    final updateDir = await _updatesDirectory();
    if (!await updateDir.exists()) {
      return;
    }

    final keepPath = keep == null ? null : (await _cachedApkFile(keep)).path;
    await for (final entity in updateDir.list()) {
      if (entity is! File) {
        continue;
      }

      final isApkCache =
          entity.path.endsWith('.apk') || entity.path.endsWith('.download');
      if (!isApkCache || entity.path == keepPath) {
        continue;
      }

      try {
        await entity.delete();
      } catch (_) {
        // Cache cleanup is best-effort and should not block update checks.
      }
    }
  }

  Future<void> _verifySha256(File file, String expectedSha256) async {
    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString().toLowerCase() == expectedSha256.toLowerCase()) {
      return;
    }

    try {
      await file.delete();
    } catch (_) {
      // Ignore cleanup errors; the verification failure is what matters.
    }
    throw Exception('安装包校验失败，请重新下载');
  }

  Future<void> _ensureInstallPermission() async {
    if (!Platform.isAndroid) {
      return;
    }

    final canInstall = await _canRequestPackageInstalls();
    if (canInstall) {
      return;
    }

    final isAllowed = await _openInstallPermissionSettings();
    if (!isAllowed) {
      throw Exception('请打开“允许安装未知应用”权限后返回继续安装');
    }
  }

  Future<bool> _canRequestPackageInstalls() async {
    final result = await _installPermissionChannel.invokeMethod<bool>(
      'canRequestPackageInstalls',
    );
    return result ?? false;
  }

  Future<List<String>> _supportedAbis() async {
    if (!Platform.isAndroid) {
      return const ['universal'];
    }

    try {
      final result = await _installPermissionChannel
          .invokeMethod<List<dynamic>>('supportedAbis');
      return result?.whereType<String>().toList() ?? const ['universal'];
    } catch (_) {
      return const ['universal'];
    }
  }

  Future<bool> _openInstallPermissionSettings() async {
    final result = await _installPermissionChannel.invokeMethod<bool>(
      'openInstallPermissionSettings',
    );
    return result ?? false;
  }

  Future<bool> _installApk(File apkFile) async {
    final result = await _installPermissionChannel.invokeMethod<bool>(
      'installApk',
      {'filePath': apkFile.path},
    );
    return result ?? false;
  }

  bool _isInstallPermissionError(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('permission denied') ||
        lowerMessage.contains('permission');
  }

  String _installErrorMessage(String message) {
    if (_isInstallPermissionError(message)) {
      return '安装权限被拒绝，请在系统设置中允许本应用安装未知应用后返回重试';
    }

    return message;
  }

  int _compareVersions(String left, String right) {
    final leftParts = left
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final rightParts = right
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final maxLength = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (var index = 0; index < maxLength; index++) {
      final leftValue = index < leftParts.length ? leftParts[index] : 0;
      final rightValue = index < rightParts.length ? rightParts[index] : 0;
      if (leftValue != rightValue) {
        return leftValue.compareTo(rightValue);
      }
    }

    return 0;
  }
}
