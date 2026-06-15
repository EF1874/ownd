import '../../shared/utils/category_tree_utils.dart';
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
    ..reminderDays = (json['reminderDays'] as num?)?.toInt() ?? 0
    ..history = ((json['itemHistories'] as List<dynamic>?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(historyFromApi)
        .toList();
  device.hasReminder = device.reminderDays > 0;

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

Map<String, dynamic> historyToApi(SubscriptionHistory history) {
  return {
    'type': 'RENEWAL',
    'price': history.price,
    if (history.recordDate != null)
      'recordDate': _dateOnlyToApi(history.recordDate!),
    if (history.note != null && history.note!.isNotEmpty) 'note': history.note,
    if (history.startDate != null)
      'startDate': _dateOnlyToApi(history.startDate!),
    if (history.endDate != null) 'endDate': _dateOnlyToApi(history.endDate!),
    'cycleType': _cycleTypeToApi(history.cycleType),
    'cycle': 1,
  };
}

Map<String, dynamic> deviceToApi(Device device) {
  final category = device.category.value;
  final isVirtual =
      device.cycleType != null ||
      CategoryTreeUtils.isVirtualSubscription(category);

  return {
    'name': device.name,
    'price': device.price,
    'purchaseDate': _dateOnlyToApi(device.purchaseDate),
    if (category?.uuid != null) 'categoryId': category!.uuid,
    if (device.platformUuid != null) 'platformId': device.platformUuid,
    if (device.notes != null) 'notes': device.notes,
    'tags': device.tags,
    'isVirtual': isVirtual,
    if (device.cycleType != null)
      'currentCycleType': _cycleTypeToApi(device.cycleType!),
    if (device.cycleType != null) 'currentCycle': 1,
    if (device.nextBillingDate != null)
      'nextBillingDate': _dateOnlyToApi(device.nextBillingDate!),
    'isAutoRenew': device.isAutoRenew,
    'reminderDays': device.hasReminder ? device.reminderDays : 0,
    if (device.warrantyEndDate != null)
      'warrantyEndDate': _dateOnlyToApi(device.warrantyEndDate!),
    'isBackup': device.backupDate != null,
    if (device.backupDate != null)
      'backupDate': _dateOnlyToApi(device.backupDate!),
    'isScrapped': device.scrapDate != null,
    if (device.scrapDate != null)
      'scrappedDate': _dateOnlyToApi(device.scrapDate!),
  };
}

DateTime? _date(dynamic value) {
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
  return null;
}

String _dateOnlyToApi(DateTime date) {
  final local = date.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
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
