import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/network/api_client.dart';
import '../../mappers/device_api_mapper.dart';
import '../../models/device.dart';
import '../device_datasource.dart';
import '../../../shared/utils/image_path_utils.dart';

class RemoteDeviceDataSource implements DeviceDataSource {
  final ApiClient _apiClient;
  final _controller = StreamController<List<Device>>.broadcast();
  List<Device> _cache = [];
  final Map<int, String> _uuidMap = {};
  final Map<String, String?> _imagePathByUuid = {};
  bool _isDisposed = false;

  RemoteDeviceDataSource(this._apiClient);

  @override
  Future<List<Device>> getAll() async {
    final data = await _apiClient.get<List<dynamic>>('/items');
    _cache = data.whereType<Map<String, dynamic>>().map(deviceFromApi).toList();
    for (final device in _cache) {
      _rememberDevice(device);
    }
    if (!_isDisposed) {
      _controller.add(List.unmodifiable(_cache));
    }
    return List.unmodifiable(_cache);
  }

  @override
  Future<Device> getById(int id) async {
    var uuid = _uuidMap[id];
    if (uuid == null) {
      await getAll();
      uuid = _uuidMap[id];
    }

    if (uuid == null) {
      throw StateError('Device with id $id not found in memory.');
    }

    final data = await _apiClient.get<Map<String, dynamic>>('/items/$uuid');
    final device = deviceFromApi(data);
    _rememberDevice(device);
    final index = _cache.indexWhere((item) => item.id == device.id);
    if (index >= 0) {
      _cache[index] = device;
    } else {
      _cache.add(device);
    }
    return device;
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
    bool expiringSoon = false,
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
      if (expiringSoon) 'expiringSoon': 'true',
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
    };
    final data = await _apiClient.get<List<dynamic>>(
      '/items',
      queryParameters: queryParameters,
    );
    final list = data
        .whereType<Map<String, dynamic>>()
        .map(deviceFromApi)
        .toList();
    for (final device in list) {
      _rememberDevice(device);
    }
    return list;
  }

  @override
  Future<void> add(Device device) async {
    final imagePath = device.imagePath;
    final uploadsImage = await _isLocalImagePath(imagePath);
    final payload = deviceToApi(device);
    if (uploadsImage) payload.remove('imagePath');

    final data = await _apiClient.post<Map<String, dynamic>>(
      '/items',
      data: payload,
    );
    var created = deviceFromApi(data);
    if (uploadsImage) {
      await _uploadImage(created.uuid, imagePath!);
      created = await _fetchByUuid(created.uuid);
    }
    device
      ..id = created.id
      ..uuid = created.uuid
      ..imagePath = created.imagePath;
    _rememberDevice(device);
    try {
      await getAll();
    } catch (_) {
      // Cache refresh failure should not block the success result
    }
  }

  @override
  Future<void> update(Device device) async {
    final imagePath = device.imagePath;
    final previousImagePath = _imagePathByUuid[device.uuid];
    final uploadsImage = await _isLocalImagePath(imagePath);
    final deletesImage =
        imagePath == null &&
        previousImagePath != null &&
        isRemoteImagePath(previousImagePath);
    final existingHistoryCount = await _getRemoteHistoryCount(device.uuid);
    final newHistories = device.history.length > existingHistoryCount
        ? device.history.skip(existingHistoryCount).toList()
        : <SubscriptionHistory>[];
    for (final history in newHistories) {
      await _apiClient.post<Map<String, dynamic>>(
        '/items/${device.uuid}/histories',
        data: historyToApi(history),
      );
    }

    final payload = deviceToApi(device);
    if (uploadsImage) payload.remove('imagePath');
    if (deletesImage) await _deleteImage(device.uuid);

    final data = await _apiClient.patch<Map<String, dynamic>>(
      '/items/${device.uuid}',
      data: payload,
    );
    if (uploadsImage) {
      await _uploadImage(device.uuid, imagePath!);
    }
    final refreshedData = uploadsImage || newHistories.isNotEmpty
        ? await _apiClient.get<Map<String, dynamic>>('/items/${device.uuid}')
        : data;
    final refreshed = deviceFromApi(refreshedData);
    device
      ..id = refreshed.id
      ..uuid = refreshed.uuid
      ..imagePath = refreshed.imagePath
      ..notes = refreshed.notes
      ..tags = refreshed.tags
      ..history = refreshed.history
      ..nextBillingDate = refreshed.nextBillingDate
      ..cycleType = refreshed.cycleType
      ..price = refreshed.price;
    _rememberDevice(device);
    try {
      await getAll();
    } catch (_) {
      // Cache refresh failure should not block the success result
    }
  }

  @override
  Future<Device> updateHistory(
    Device device,
    SubscriptionHistory history,
  ) async {
    final historyId = history.uuid;
    if (historyId == null || historyId.isEmpty) {
      throw StateError('这条订阅记录暂时无法编辑，请刷新后再试');
    }

    await _apiClient.patch<Map<String, dynamic>>(
      '/items/${device.uuid}/histories/$historyId',
      data: historyToApi(history, includeNullNote: true),
    );
    return _refreshDevice(device);
  }

  @override
  Future<Device> deleteHistory(
    Device device,
    SubscriptionHistory history,
  ) async {
    final historyId = history.uuid;
    if (historyId == null || historyId.isEmpty) {
      throw StateError('这条订阅记录暂时无法删除，请刷新后再试');
    }

    await _apiClient.delete<dynamic>(
      '/items/${device.uuid}/histories/$historyId',
    );
    return _refreshDevice(device);
  }

  Future<Device> _refreshDevice(Device device) async {
    final data = await _apiClient.get<Map<String, dynamic>>(
      '/items/${device.uuid}',
    );
    final refreshed = deviceFromApi(data);
    device
      ..id = refreshed.id
      ..uuid = refreshed.uuid
      ..history = refreshed.history
      ..nextBillingDate = refreshed.nextBillingDate
      ..cycleType = refreshed.cycleType
      ..price = refreshed.price
      ..periodPrice = refreshed.periodPrice;
    _rememberDevice(device);
    try {
      await getAll();
    } catch (_) {
      // Cache refresh failure should not block the success result
    }
    return device;
  }

  Future<Device> _fetchByUuid(String uuid) async {
    final data = await _apiClient.get<Map<String, dynamic>>('/items/$uuid');
    return deviceFromApi(data);
  }

  Future<void> _uploadImage(String uuid, String imagePath) async {
    final contentType = await _imageContentType(imagePath);
    await _apiClient.post<Map<String, dynamic>>(
      '/items/$uuid/image',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imagePath,
          filename: p.basename(imagePath),
          contentType: contentType,
        ),
      }),
    );
  }

  Future<void> _deleteImage(String uuid) async {
    await _apiClient.delete<dynamic>('/items/$uuid/image');
  }

  Future<DioMediaType> _imageContentType(String imagePath) async {
    final bytes = await File(imagePath).openRead(0, 12).first;
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return DioMediaType.parse('image/png');
    }
    return DioMediaType.parse('image/jpeg');
  }

  Future<bool> _isLocalImagePath(String? imagePath) async {
    if (imagePath == null || isRemoteImagePath(imagePath)) return false;
    return File(imagePath).exists();
  }

  Future<int> _getRemoteHistoryCount(String itemUuid) async {
    final data = await _apiClient.get<Map<String, dynamic>>('/items/$itemUuid');
    final histories = data['itemHistories'];
    if (histories is List) return histories.length;
    return 0;
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
        orElse: () =>
            throw StateError('Device with id $id not found in memory.'),
      );
      debugPrint('[DataSource] Calling DELETE /items/${device.uuid}');
      await _apiClient.delete<dynamic>('/items/${device.uuid}');
    }
    _cache.removeWhere((d) => d.id == id);
    final removedUuid = _uuidMap.remove(id);
    if (removedUuid != null) _imagePathByUuid.remove(removedUuid);
    debugPrint('[DataSource] delete($id) completed successfully');
  }

  void _rememberDevice(Device device) {
    _uuidMap[device.id] = device.uuid;
    _imagePathByUuid[device.uuid] = device.imagePath;
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _cache = [];
    _uuidMap.clear();
    _imagePathByUuid.clear();
    await _controller.close();
  }
}
