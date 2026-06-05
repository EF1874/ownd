import '../models/device.dart';

/// Abstract data source interface for Device entities.
/// This abstraction enables swapping between local (Isar) and
/// remote (REST API) implementations without modifying the Repository.
abstract class DeviceDataSource {
  /// Get all devices.
  Future<List<Device>> getAll();

  /// Watch all devices as a reactive stream.
  Stream<List<Device>> watchAll();

  /// Get paginated and filtered devices.
  Future<List<Device>> getPaginated({
    required int page,
    required int limit,
    String? search,
    String? categoryId,
    String? platformId,
    String? tag,
    String? sortBy,
    String? sortOrder,
  });

  /// Add a new device.
  Future<void> add(Device device);

  /// Update an existing device.
  Future<void> update(Device device);

  /// Delete a device by its ID.
  Future<void> delete(int id);
}
