import '../../shared/config/category_config.dart';
import '../models/device.dart';
import 'api_id_mapper.dart';
import 'category_api_mapper.dart';

Device deviceFromApi(Map<String, dynamic> json) {
  final device = Device()
    ..id = stableIntId(json['id'] as String)
    ..uuid = json['id'] as String
    ..name = json['name'] as String
    ..price = (json['price'] as num?)?.toDouble() ?? 0
    ..purchaseDate = _date(json['purchaseDate']) ?? DateTime.now()
    ..warrantyEndDate = _date(json['warrantyEndDate'])
    ..backupDate = _date(json['backupDate'])
    ..scrapDate = _date(json['scrappedDate'])
    ..platform = (json['platform'] as Map<String, dynamic>?)?['name'] as String?
    ..platformUuid =
        (json['platform'] as Map<String, dynamic>?)?['id'] as String?
    ..imagePath = json['imagePath'] as String?
    ..notes = json['notes'] as String?
    ..tags = ((json['tags'] as List<dynamic>?) ?? const [])
        .whereType<String>()
        .toList()
    ..cycleType = _cycleTypeFromApi(json['currentCycleType'] as String?)
    ..isAutoRenew = json['isAutoRenew'] as bool? ?? false
    ..nextBillingDate = _date(json['nextBillingDate'])
    ..periodPrice = (json['isVirtual'] as bool? ?? false)
        ? (json['price'] as num?)?.toDouble()
        : null
    ..hasReminder = false
    ..reminderDays = 1
    ..history = ((json['itemHistories'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(historyFromApi)
        .toList();

  final categoryJson = json['category'];
  if (categoryJson is Map<String, dynamic>) {
    device.category.value = categoryFromApi(categoryJson);
  }

  return device;
}

SubscriptionHistory historyFromApi(Map<String, dynamic> json) {
  return SubscriptionHistory()
    ..startDate = _date(json['startDate'])
    ..endDate = _date(json['endDate'])
    ..price = (json['price'] as num?)?.toDouble() ?? 0
    ..cycleType =
        _cycleTypeFromApi(json['cycleType'] as String?) ?? CycleType.monthly
    ..recordDate = _date(json['recordDate'])
    ..note = json['note'] as String?;
}

Map<String, dynamic> deviceToApi(Device device) {
  final category = device.category.value;
  final isVirtual =
      device.cycleType != null ||
      (category?.parentName ??
              CategoryConfig.getMajorCategory(category?.name)) ==
          '虚拟订阅';

  return {
    'name': device.name,
    'price': device.price,
    'purchaseDate': device.purchaseDate.toIso8601String(),
    if (category?.uuid != null) 'categoryId': category!.uuid,
    if (device.platformUuid != null) 'platformId': device.platformUuid,
    if (device.notes != null) 'notes': device.notes,
    'tags': device.tags,
    'isVirtual': isVirtual,
    if (device.cycleType != null)
      'currentCycleType': _cycleTypeToApi(device.cycleType!),
    if (device.cycleType != null) 'currentCycle': 1,
    'isAutoRenew': device.isAutoRenew,
    if (device.warrantyEndDate != null)
      'warrantyEndDate': device.warrantyEndDate!.toIso8601String(),
    'isBackup': device.backupDate != null,
    if (device.backupDate != null)
      'backupDate': device.backupDate!.toIso8601String(),
    'isScrapped': device.scrapDate != null,
    if (device.scrapDate != null)
      'scrappedDate': device.scrapDate!.toIso8601String(),
  };
}

DateTime? _date(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

CycleType? _cycleTypeFromApi(String? value) {
  return switch (value) {
    'DAY' => CycleType.daily,
    'WEEK' => CycleType.weekly,
    'MONTH' => CycleType.monthly,
    'QUARTER' => CycleType.quarterly,
    'YEAR' => CycleType.yearly,
    _ => null,
  };
}

String _cycleTypeToApi(CycleType cycleType) {
  return switch (cycleType) {
    CycleType.daily => 'DAY',
    CycleType.weekly => 'WEEK',
    CycleType.monthly => 'MONTH',
    CycleType.quarterly => 'QUARTER',
    CycleType.yearly => 'YEAR',
    CycleType.oneTime => 'YEAR',
  };
}
