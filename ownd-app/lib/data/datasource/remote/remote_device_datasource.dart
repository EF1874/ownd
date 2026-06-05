import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../mappers/device_api_mapper.dart';
import '../../models/device.dart';
import '../device_datasource.dart';

class RemoteDeviceDataSource implements DeviceDataSource {
  final ApiClient _apiClient;
  final _controller = StreamController<List<Device>>.broadcast();
  List<Device> _cache = [];
  final Map<int, String> _uuidMap = {};
  bool _isDisposed = false;

  RemoteDeviceDataSource(this._apiClient);

  @override
  Future<List<Device>> getAll() async {
    final data = await _apiClient.get<List<dynamic>>('/items');
    _cache = data.whereType<Map<String, dynamic>>().map(deviceFromApi).toList();
    for (final device in _cache) {
      _uuidMap[device.id] = device.uuid;
    }
    if (!_isDisposed) {
      _controller.add(List.unmodifiable(_cache));
    }
    return List.unmodifiable(_cache);
  }

  @override
  Stream<List<Device>> watchAll() {
    unawaited(getAll());
    return _controller.stream;
  }

  @override
  Future<List<Device>> getPaginated({
    required int page,
    required int limit,
    String? search,
    String? categoryId,
    String? platformId,
    String? tag,
    String? sortBy,
    String? sortOrder,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (platformId != null && platformId.isNotEmpty) 'platformId': platformId,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
    };
    final data = await _apiClient.get<List<dynamic>>(
      '/items',
      queryParameters: queryParameters,
    );
    final list = data.whereType<Map<String, dynamic>>().map(deviceFromApi).toList();
    for (final device in list) {
      _uuidMap[device.id] = device.uuid;
    }
    return list;
  }

  @override
  Future<void> add(Device device) async {
    final data = await _apiClient.post<Map<String, dynamic>>(
      '/items',
      data: deviceToApi(device),
    );
    final created = deviceFromApi(data);
    device
      ..id = created.id
      ..uuid = created.uuid;
    _uuidMap[device.id] = device.uuid;
    try {
      await getAll();
    } catch (_) {
      // Cache refresh failure should not block the success result
    }
  }

  @override
  Future<void> update(Device device) async {
    final data = await _apiClient.patch<Map<String, dynamic>>(
      '/items/${device.uuid}',
      data: deviceToApi(device),
    );
    final updated = deviceFromApi(data);
    device
      ..id = updated.id
      ..uuid = updated.uuid;
    _uuidMap[device.id] = device.uuid;
    try {
      await getAll();
    } catch (_) {
      // Cache refresh failure should not block the success result
    }
  }

  @override
  Future<void> delete(int id) async {
    final uuid = _uuidMap[id];
    debugPrint('[DataSource] delete($id), uuid=$uuid');
    if (uuid != null) {
      debugPrint('[DataSource] Calling DELETE /items/$uuid');
      await _apiClient.delete<dynamic>('/items/$uuid');
    } else {
      final device = _cache.firstWhere(
        (item) => item.id == id,
        orElse: () => throw StateError('Device with id $id not found in memory.'),
      );
      debugPrint('[DataSource] Calling DELETE /items/${device.uuid}');
      await _apiClient.delete<dynamic>('/items/${device.uuid}');
    }
    _cache.removeWhere((d) => d.id == id);
    _uuidMap.remove(id);
    debugPrint('[DataSource] delete($id) completed successfully');
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _cache = [];
    _uuidMap.clear();
    await _controller.close();
  }
}
