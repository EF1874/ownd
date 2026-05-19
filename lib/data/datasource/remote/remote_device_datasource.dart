import 'dart:async';

import '../../../core/network/api_client.dart';
import '../../mappers/device_api_mapper.dart';
import '../../models/device.dart';
import '../device_datasource.dart';

class RemoteDeviceDataSource implements DeviceDataSource {
  final ApiClient _apiClient;
  final _controller = StreamController<List<Device>>.broadcast();
  List<Device> _cache = [];

  RemoteDeviceDataSource(this._apiClient);

  @override
  Future<List<Device>> getAll() async {
    final data = await _apiClient.get<List<dynamic>>('/items');
    _cache = data.whereType<Map<String, dynamic>>().map(deviceFromApi).toList();
    _controller.add(List.unmodifiable(_cache));
    return List.unmodifiable(_cache);
  }

  @override
  Stream<List<Device>> watchAll() {
    unawaited(getAll());
    return _controller.stream;
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
    await getAll();
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
    await getAll();
  }

  @override
  Future<void> delete(int id) async {
    final device = _cache.firstWhere((item) => item.id == id);
    await _apiClient.delete<dynamic>('/items/${device.uuid}');
    await getAll();
  }
}
