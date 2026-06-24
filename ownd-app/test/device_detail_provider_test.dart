import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ownd/core/network/api_exception.dart';
import 'package:ownd/data/datasource/device_datasource.dart';
import 'package:ownd/data/models/device.dart';
import 'package:ownd/data/repositories/device_repository.dart';
import 'package:ownd/features/device_detail/device_detail_screen.dart';

void main() {
  test('device detail refetches after a cached failure is released', () async {
    final dataSource = _FailThenRecoverDeviceDataSource();
    final container = ProviderContainer(
      overrides: [
        deviceRepositoryProvider.overrideWithValue(
          DeviceRepository(dataSource),
        ),
      ],
    );
    addTearDown(container.dispose);

    final firstScreen = container.listen(deviceDetailProvider(1), (_, _) {});
    await expectLater(
      container.read(deviceDetailProvider(1).future),
      throwsA(isA<ApiException>()),
    );

    firstScreen.close();
    await container.pump();
    dataSource.fail = false;

    final secondScreen = container.listen(deviceDetailProvider(1), (_, _) {});
    addTearDown(secondScreen.close);
    final device = await container.read(deviceDetailProvider(1).future);

    expect(device.name, 'Recovered');
    expect(dataSource.getByIdCalls, 2);
  });
}

class _FailThenRecoverDeviceDataSource implements DeviceDataSource {
  bool fail = true;
  int getByIdCalls = 0;

  @override
  Future<Device> getById(int id) async {
    getByIdCalls++;
    if (fail) throw const ApiException('网络连接失败');
    return Device()
      ..id = id
      ..uuid = 'device-$id'
      ..name = 'Recovered'
      ..purchaseDate = DateTime(2026, 1, 1);
  }

  @override
  Future<List<Device>> getAll() async => const [];

  @override
  Stream<List<Device>> watchAll() => const Stream.empty();

  @override
  Future<List<Device>> getPaginated({
    required int page,
    required int limit,
    String? search,
    String? categoryId,
    String? platformId,
    String? tag,
    bool expiringSoon = false,
    String? sortBy,
    String? sortOrder,
  }) async => const [];

  @override
  Future<void> add(Device device) async {}

  @override
  Future<void> update(Device device) async {}

  @override
  Future<Device> updateHistory(
    Device device,
    SubscriptionHistory history,
  ) async => device;

  @override
  Future<Device> deleteHistory(
    Device device,
    SubscriptionHistory history,
  ) async => device;

  @override
  Future<void> delete(int id) async {}
}
