import 'package:isar/isar.dart';
import '../../models/device.dart';
import '../device_datasource.dart';

/// Isar-based local implementation of [DeviceDataSource].
class IsarDeviceDataSource implements DeviceDataSource {
  final Isar _isar;

  IsarDeviceDataSource(this._isar);

  @override
  Future<List<Device>> getAll() async {
    return await _isar.devices.where().findAll();
  }

  @override
  Stream<List<Device>> watchAll() {
    return _isar.devices.where().watch(fireImmediately: true);
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
  }) {
    throw UnimplementedError('getPaginated is not supported in local Isar datasource');
  }

  @override
  Future<void> add(Device device) async {
    await _isar.writeTxn(() async {
      await _isar.devices.put(device);
      await device.category.save();
    });
  }

  @override
  Future<void> update(Device device) async {
    await _isar.writeTxn(() async {
      await _isar.devices.put(device);
      await device.category.save();
    });
  }

  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.devices.delete(id);
    });
  }
}
