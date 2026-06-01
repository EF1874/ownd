import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../datasource/remote/remote_platform_datasource.dart';
import '../models/purchase_platform.dart';

final platformRepositoryProvider = Provider<PlatformRepository>((ref) {
  return PlatformRepository(
    RemotePlatformDataSource(ref.watch(apiClientProvider)),
  );
});

final platformsProvider = FutureProvider<List<PurchasePlatform>>((ref) async {
  return ref.read(platformRepositoryProvider).getAllPlatforms();
});

class PlatformRepository {
  final RemotePlatformDataSource _dataSource;

  PlatformRepository(this._dataSource);

  Future<List<PurchasePlatform>> getAllPlatforms() => _dataSource.getAll();

  Future<PurchasePlatform?> findPlatformByName(String name) {
    return _dataSource.findByName(name);
  }

  Future<PurchasePlatform> ensurePlatform(String name) async {
    final existing = await findPlatformByName(name);
    if (existing != null) return existing;

    return _dataSource.add(name);
  }
}
