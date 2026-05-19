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

  Stream<List<Device>> watchAllDevices() => _dataSource.watchAll();

  Future<void> addDevice(Device device) => _dataSource.add(device);

  Future<void> updateDevice(Device device) => _dataSource.update(device);

  Future<void> deleteDevice(int id) => _dataSource.delete(id);
}
