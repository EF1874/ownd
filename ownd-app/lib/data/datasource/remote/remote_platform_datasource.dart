import '../../../core/network/api_client.dart';
import '../../mappers/platform_api_mapper.dart';
import '../../models/purchase_platform.dart';

class RemotePlatformDataSource {
  final ApiClient _apiClient;
  List<PurchasePlatform> _cache = [];

  RemotePlatformDataSource(this._apiClient);

  Future<List<PurchasePlatform>> getAll() async {
    final data = await _apiClient.get<List<dynamic>>('/platform');
    _cache = data
        .whereType<Map<String, dynamic>>()
        .map(platformFromApi)
        .toList();
    return List.unmodifiable(_cache);
  }

  Future<PurchasePlatform> add(String name) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      '/platform',
      data: platformToApi(name),
    );
    final platform = platformFromApi(data);
    await getAll();
    return platform;
  }

  Future<PurchasePlatform?> findByName(String name) async {
    if (_cache.isEmpty) await getAll();

    for (final platform in _cache) {
      if (platform.name == name) return platform;
    }

    return null;
  }
}
