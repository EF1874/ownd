import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/token_storage.dart';
import '../utils/image_path_utils.dart';

final _imageTokenProvider = FutureProvider<String?>(
  (ref) => ref.watch(tokenStorageProvider).readToken(),
);

class AppImage extends ConsumerWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;

  const AppImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
        final shouldResize = fit == BoxFit.cover;
        final resolvedCacheWidth =
            cacheWidth ??
            (shouldResize
                ? _cacheExtent(width, constraints.maxWidth, devicePixelRatio)
                : null);
        final resolvedCacheHeight =
            cacheHeight ??
            (shouldResize
                ? _cacheExtent(height, constraints.maxHeight, devicePixelRatio)
                : null);

        return _buildImage(
          context,
          ref,
          cacheWidth: resolvedCacheWidth,
          cacheHeight: resolvedCacheHeight,
        );
      },
    );
  }

  Widget _buildImage(
    BuildContext context,
    WidgetRef ref, {
    required int? cacheWidth,
    required int? cacheHeight,
  }) {
    if (!isRemoteImagePath(path)) {
      return Image.file(
        File(path),
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    final token = ref.watch(_imageTokenProvider);
    return token.when(
      data: (value) => Image.network(
        imageUrlForPath(path),
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        headers: value == null || value.isEmpty
            ? null
            : {'Authorization': 'Bearer $value'},
        errorBuilder: (_, __, ___) => _fallback(context),
      ),
      loading: () => _fallback(context),
      error: (_, __) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  int? _cacheExtent(double? explicitExtent, double constraint, double ratio) {
    final extent = explicitExtent ?? constraint;
    if (!extent.isFinite || extent <= 0) return null;
    return (extent * ratio).round();
  }
}
