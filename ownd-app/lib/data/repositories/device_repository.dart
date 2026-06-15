import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device.dart';
import '../datasource/device_datasource.dart';
import '../datasource/remote/remote_device_datasource.dart';
import '../../core/network/api_client.dart';

/// Riverpod provider for the DeviceDataSource.
/// Swap this to a remote implementation when backend is ready.
final deviceDataSourceProvider = Provider<DeviceDataSource>((ref) {
  final dataSource = RemoteDeviceDataSource(ref.watch(apiClientProvider));
  ref.onDispose(dataSource.dispose);
  return dataSource;
});

/// Riverpod provider for the DeviceRepository.
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final dataSource = ref.watch(deviceDataSourceProvider);
  return DeviceRepository(dataSource);
});

/// Repository layer for Device entities.
/// Business logic lives here; data access is delegated to [DeviceDataSource].
class DeviceRepository {
  final DeviceDataSource _dataSource;

  DeviceRepository(this._dataSource);

  Future<List<Device>> getAllDevices() => _dataSource.getAll();

  Future<Device> getDevice(int id) => _dataSource.getById(id);

  Stream<List<Device>> watchAllDevices() => _dataSource.watchAll();

  Future<List<Device>> getPaginatedDevices({
    required int page,
    required int limit,
    String? search,
    String? categoryId,
    String? platformId,
    String? tag,
    bool expiringSoon = false,
    String? sortBy,
    String? sortOrder,
  }) {
    return _dataSource.getPaginated(
      page: page,
      limit: limit,
      search: search,
      categoryId: categoryId,
      platformId: platformId,
      tag: tag,
      expiringSoon: expiringSoon,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
  }

  Future<void> addDevice(Device device) => _dataSource.add(device);

  Future<void> updateDevice(Device device) => _dataSource.update(device);

  Future<Device> updateHistory(Device device, SubscriptionHistory history) =>
      _dataSource.updateHistory(device, history);

  Future<Device> deleteHistory(Device device, SubscriptionHistory history) =>
      _dataSource.deleteHistory(device, history);

  Future<void> deleteDevice(int id) => _dataSource.delete(id);
}
