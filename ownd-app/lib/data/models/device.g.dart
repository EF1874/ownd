// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDeviceCollection on Isar {
  IsarCollection<Device> get devices => this.collection();
}

const DeviceSchema = CollectionSchema(
  name: r'Device',
  id: 3491430514663294648,
  properties: {
    r'backupDate': PropertySchema(
      id: 0,
      name: r'backupDate',
      type: IsarType.dateTime,
    ),
    r'customIconPath': PropertySchema(
      id: 1,
      name: r'customIconPath',
      type: IsarType.string,
    ),
    r'cycleCalculationMode': PropertySchema(
      id: 2,
      name: r'cycleCalculationMode',
      type: IsarType.string,
      enumMap: _DevicecycleCalculationModeEnumValueMap,
    ),
    r'cycleDays': PropertySchema(
      id: 3,
      name: r'cycleDays',
      type: IsarType.long,
    ),
    r'cycleType': PropertySchema(
      id: 4,
      name: r'cycleType',
      type: IsarType.string,
      enumMap: _DevicecycleTypeEnumValueMap,
    ),
    r'dailyCost': PropertySchema(
      id: 5,
      name: r'dailyCost',
      type: IsarType.double,
    ),
    r'daysUsed': PropertySchema(
      id: 6,
      name: r'daysUsed',
      type: IsarType.long,
    ),
    r'expectedLifeYears': PropertySchema(
      id: 7,
      name: r'expectedLifeYears',
      type: IsarType.double,
    ),
    r'hasReminder': PropertySchema(
      id: 8,
      name: r'hasReminder',
      type: IsarType.bool,
    ),
    r'history': PropertySchema(
      id: 9,
      name: r'history',
      type: IsarType.objectList,
      target: r'SubscriptionHistory',
    ),
    r'imagePath': PropertySchema(
      id: 10,
      name: r'imagePath',
      type: IsarType.string,
    ),
    r'isAutoRenew': PropertySchema(
      id: 11,
      name: r'isAutoRenew',
      type: IsarType.bool,
    ),
    r'lastUsedDate': PropertySchema(
      id: 12,
      name: r'lastUsedDate',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 13,
      name: r'name',
      type: IsarType.string,
    ),
    r'nextBillingDate': PropertySchema(
      id: 14,
      name: r'nextBillingDate',
      type: IsarType.dateTime,
    ),
    r'notes': PropertySchema(
      id: 15,
      name: r'notes',
      type: IsarType.string,
    ),
    r'periodPrice': PropertySchema(
      id: 16,
      name: r'periodPrice',
      type: IsarType.double,
    ),
    r'platform': PropertySchema(
      id: 17,
      name: r'platform',
      type: IsarType.string,
    ),
    r'price': PropertySchema(
      id: 18,
      name: r'price',
      type: IsarType.double,
    ),
    r'purchaseDate': PropertySchema(
      id: 19,
      name: r'purchaseDate',
      type: IsarType.dateTime,
    ),
    r'renewalPrice': PropertySchema(
      id: 20,
      name: r'renewalPrice',
      type: IsarType.double,
    ),
    r'scrapDate': PropertySchema(
      id: 21,
      name: r'scrapDate',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(
      id: 22,
      name: r'status',
      type: IsarType.string,
    ),
    r'subscriptionDueDate': PropertySchema(
      id: 23,
      name: r'subscriptionDueDate',
      type: IsarType.dateTime,
    ),
    r'tags': PropertySchema(
      id: 24,
      name: r'tags',
      type: IsarType.stringList,
    ),
    r'totalAccumulatedPrice': PropertySchema(
      id: 25,
      name: r'totalAccumulatedPrice',
      type: IsarType.double,
    ),
    r'usageCount': PropertySchema(
      id: 26,
      name: r'usageCount',
      type: IsarType.long,
    ),
    r'uuid': PropertySchema(
      id: 27,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'warrantyEndDate': PropertySchema(
      id: 28,
      name: r'warrantyEndDate',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _deviceEstimateSize,
  serialize: _deviceSerialize,
  deserialize: _deviceDeserialize,
  deserializeProp: _deviceDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'category': LinkSchema(
      id: -5597867658741470952,
      name: r'category',
      target: r'Category',
      single: true,
    )
  },
  embeddedSchemas: {r'SubscriptionHistory': SubscriptionHistorySchema},
  getId: _deviceGetId,
  getLinks: _deviceGetLinks,
  attach: _deviceAttach,
  version: '3.1.0+1',
);

int _deviceEstimateSize(
  Device object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.customIconPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.cycleCalculationMode.name.length * 3;
  {
    final value = object.cycleType;
    if (value != null) {
      bytesCount += 3 + value.name.length * 3;
    }
  }
  bytesCount += 3 + object.history.length * 3;
  {
    final offsets = allOffsets[SubscriptionHistory]!;
    for (var i = 0; i < object.history.length; i++) {
      final value = object.history[i];
      bytesCount +=
          SubscriptionHistorySchema.estimateSize(value, offsets, allOffsets);
    }
  }
  {
    final value = object.imagePath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.platform;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.status.length * 3;
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _deviceSerialize(
  Device object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.backupDate);
  writer.writeString(offsets[1], object.customIconPath);
  writer.writeString(offsets[2], object.cycleCalculationMode.name);
  writer.writeLong(offsets[3], object.cycleDays);
  writer.writeString(offsets[4], object.cycleType?.name);
  writer.writeDouble(offsets[5], object.dailyCost);
  writer.writeLong(offsets[6], object.daysUsed);
  writer.writeDouble(offsets[7], object.expectedLifeYears);
  writer.writeBool(offsets[8], object.hasReminder);
  writer.writeObjectList<SubscriptionHistory>(
    offsets[9],
    allOffsets,
    SubscriptionHistorySchema.serialize,
    object.history,
  );
  writer.writeString(offsets[10], object.imagePath);
  writer.writeBool(offsets[11], object.isAutoRenew);
  writer.writeDateTime(offsets[12], object.lastUsedDate);
  writer.writeString(offsets[13], object.name);
  writer.writeDateTime(offsets[14], object.nextBillingDate);
  writer.writeString(offsets[15], object.notes);
  writer.writeDouble(offsets[16], object.periodPrice);
  writer.writeString(offsets[17], object.platform);
  writer.writeDouble(offsets[18], object.price);
  writer.writeDateTime(offsets[19], object.purchaseDate);
  writer.writeDouble(offsets[20], object.renewalPrice);
  writer.writeDateTime(offsets[21], object.scrapDate);
  writer.writeString(offsets[22], object.status);
  writer.writeDateTime(offsets[23], object.subscriptionDueDate);
  writer.writeStringList(offsets[24], object.tags);
  writer.writeDouble(offsets[25], object.totalAccumulatedPrice);
  writer.writeLong(offsets[26], object.usageCount);
  writer.writeString(offsets[27], object.uuid);
  writer.writeDateTime(offsets[28], object.warrantyEndDate);
}

Device _deviceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Device();
  object.backupDate = reader.readDateTimeOrNull(offsets[0]);
  object.customIconPath = reader.readStringOrNull(offsets[1]);
  object.cycleCalculationMode = _DevicecycleCalculationModeValueEnumMap[
          reader.readStringOrNull(offsets[2])] ??
      CycleCalculationMode.calendar;
  object.cycleDays = reader.readLongOrNull(offsets[3]);
  object.cycleType =
      _DevicecycleTypeValueEnumMap[reader.readStringOrNull(offsets[4])];
  object.expectedLifeYears = reader.readDoubleOrNull(offsets[7]);
  object.hasReminder = reader.readBool(offsets[8]);
  object.history = reader.readObjectList<SubscriptionHistory>(
        offsets[9],
        SubscriptionHistorySchema.deserialize,
        allOffsets,
        SubscriptionHistory(),
      ) ??
      [];
  object.id = id;
  object.imagePath = reader.readStringOrNull(offsets[10]);
  object.isAutoRenew = reader.readBool(offsets[11]);
  object.lastUsedDate = reader.readDateTimeOrNull(offsets[12]);
  object.name = reader.readString(offsets[13]);
  object.nextBillingDate = reader.readDateTimeOrNull(offsets[14]);
  object.notes = reader.readStringOrNull(offsets[15]);
  object.periodPrice = reader.readDoubleOrNull(offsets[16]);
  object.platform = reader.readStringOrNull(offsets[17]);
  object.price = reader.readDouble(offsets[18]);
  object.purchaseDate = reader.readDateTime(offsets[19]);
  object.renewalPrice = reader.readDoubleOrNull(offsets[20]);
  object.scrapDate = reader.readDateTimeOrNull(offsets[21]);
  object.tags = reader.readStringList(offsets[24]) ?? [];
  object.totalAccumulatedPrice = reader.readDouble(offsets[25]);
  object.usageCount = reader.readLong(offsets[26]);
  object.uuid = reader.readString(offsets[27]);
  object.warrantyEndDate = reader.readDateTimeOrNull(offsets[28]);
  return object;
}

P _deviceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (_DevicecycleCalculationModeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          CycleCalculationMode.calendar) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (_DevicecycleTypeValueEnumMap[reader.readStringOrNull(offset)])
          as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readObjectList<SubscriptionHistory>(
            offset,
            SubscriptionHistorySchema.deserialize,
            allOffsets,
            SubscriptionHistory(),
          ) ??
          []) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 13:
      return (reader.readString(offset)) as P;
    case 14:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset)) as P;
    case 17:
      return (reader.readStringOrNull(offset)) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (reader.readDateTime(offset)) as P;
    case 20:
      return (reader.readDoubleOrNull(offset)) as P;
    case 21:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 22:
      return (reader.readString(offset)) as P;
    case 23:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 24:
      return (reader.readStringList(offset) ?? []) as P;
    case 25:
      return (reader.readDouble(offset)) as P;
    case 26:
      return (reader.readLong(offset)) as P;
    case 27:
      return (reader.readString(offset)) as P;
    case 28:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DevicecycleCalculationModeEnumValueMap = {
  r'calendar': r'calendar',
  r'fixedDays': r'fixedDays',
};
const _DevicecycleCalculationModeValueEnumMap = {
  r'calendar': CycleCalculationMode.calendar,
  r'fixedDays': CycleCalculationMode.fixedDays,
};
const _DevicecycleTypeEnumValueMap = {
  r'daily': r'daily',
  r'weekly': r'weekly',
  r'monthly': r'monthly',
  r'quarterly': r'quarterly',
  r'halfYearly': r'halfYearly',
  r'yearly': r'yearly',
  r'oneTime': r'oneTime',
};
const _DevicecycleTypeValueEnumMap = {
  r'daily': CycleType.daily,
  r'weekly': CycleType.weekly,
  r'monthly': CycleType.monthly,
  r'quarterly': CycleType.quarterly,
  r'halfYearly': CycleType.halfYearly,
  r'yearly': CycleType.yearly,
  r'oneTime': CycleType.oneTime,
};

Id _deviceGetId(Device object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _deviceGetLinks(Device object) {
  return [object.category];
}

void _deviceAttach(IsarCollection<dynamic> col, Id id, Device object) {
  object.id = id;
  object.category.attach(col, col.isar.collection<Category>(), r'category', id);
}

extension DeviceQueryWhereSort on QueryBuilder<Device, Device, QWhere> {
  QueryBuilder<Device, Device, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DeviceQueryWhere on QueryBuilder<Device, Device, QWhereClause> {
  QueryBuilder<Device, Device, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Device, Device, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Device, Device, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DeviceQueryFilter on QueryBuilder<Device, Device, QFilterCondition> {
  QueryBuilder<Device, Device, QAfterFilterCondition> backupDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'backupDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> backupDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'backupDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> backupDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'backupDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> backupDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'backupDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> backupDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'backupDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> backupDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'backupDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> customIconPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customIconPath',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      customIconPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customIconPath',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> customIconPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customIconPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> customIconPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customIconPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> customIconPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customIconPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> customIconPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customIconPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> customIconPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customIconPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> customIconPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customIconPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> customIconPathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customIconPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> customIconPathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customIconPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> customIconPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customIconPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      customIconPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customIconPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      cycleCalculationModeEqualTo(
    CycleCalculationMode value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      cycleCalculationModeGreaterThan(
    CycleCalculationMode value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      cycleCalculationModeLessThan(
    CycleCalculationMode value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      cycleCalculationModeBetween(
    CycleCalculationMode lower,
    CycleCalculationMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cycleCalculationMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      cycleCalculationModeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      cycleCalculationModeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      cycleCalculationModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      cycleCalculationModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cycleCalculationMode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      cycleCalculationModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleCalculationMode',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      cycleCalculationModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cycleCalculationMode',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleDaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cycleDays',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleDaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cycleDays',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleDaysEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleDaysGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cycleDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleDaysLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cycleDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleDaysBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cycleDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cycleType',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cycleType',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeEqualTo(
    CycleType? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeGreaterThan(
    CycleType? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeLessThan(
    CycleType? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeBetween(
    CycleType? lower,
    CycleType? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cycleType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cycleType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleType',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> cycleTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cycleType',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> dailyCostEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> dailyCostGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> dailyCostLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyCost',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> dailyCostBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> daysUsedEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'daysUsed',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> daysUsedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'daysUsed',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> daysUsedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'daysUsed',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> daysUsedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'daysUsed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      expectedLifeYearsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expectedLifeYears',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      expectedLifeYearsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expectedLifeYears',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> expectedLifeYearsEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expectedLifeYears',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      expectedLifeYearsGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expectedLifeYears',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> expectedLifeYearsLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expectedLifeYears',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> expectedLifeYearsBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expectedLifeYears',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> hasReminderEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'hasReminder',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> historyLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'history',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> historyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'history',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> historyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'history',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> historyLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'history',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> historyLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'history',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> historyLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'history',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'imagePath',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'imagePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'imagePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'imagePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> imagePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'imagePath',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> isAutoRenewEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAutoRenew',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> lastUsedDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastUsedDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> lastUsedDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastUsedDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> lastUsedDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUsedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> lastUsedDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUsedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> lastUsedDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUsedDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> lastUsedDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUsedDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nextBillingDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nextBillingDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      nextBillingDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nextBillingDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nextBillingDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nextBillingDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      nextBillingDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nextBillingDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nextBillingDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nextBillingDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> nextBillingDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nextBillingDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> periodPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'periodPrice',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> periodPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'periodPrice',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> periodPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'periodPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> periodPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'periodPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> periodPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'periodPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> periodPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'periodPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'platform',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'platform',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'platform',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'platform',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'platform',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'platform',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> platformIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'platform',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> priceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> priceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> priceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> priceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> purchaseDateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'purchaseDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> purchaseDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'purchaseDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> purchaseDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'purchaseDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> purchaseDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'purchaseDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> renewalPriceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'renewalPrice',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> renewalPriceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'renewalPrice',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> renewalPriceEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'renewalPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> renewalPriceGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'renewalPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> renewalPriceLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'renewalPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> renewalPriceBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'renewalPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> scrapDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scrapDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> scrapDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scrapDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> scrapDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scrapDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> scrapDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scrapDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> scrapDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scrapDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> scrapDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scrapDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> statusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'status',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> statusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> statusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> statusContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'status',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> statusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'status',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'status',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      subscriptionDueDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'subscriptionDueDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      subscriptionDueDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'subscriptionDueDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      subscriptionDueDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'subscriptionDueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      subscriptionDueDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'subscriptionDueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      subscriptionDueDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'subscriptionDueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      subscriptionDueDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'subscriptionDueDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsElementContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsElementMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      totalAccumulatedPriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalAccumulatedPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      totalAccumulatedPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalAccumulatedPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      totalAccumulatedPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalAccumulatedPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      totalAccumulatedPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalAccumulatedPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> usageCountEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'usageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> usageCountGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'usageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> usageCountLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'usageCount',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> usageCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'usageCount',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> uuidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> uuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> warrantyEndDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'warrantyEndDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      warrantyEndDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'warrantyEndDate',
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> warrantyEndDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'warrantyEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition>
      warrantyEndDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'warrantyEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> warrantyEndDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'warrantyEndDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> warrantyEndDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'warrantyEndDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DeviceQueryObject on QueryBuilder<Device, Device, QFilterCondition> {
  QueryBuilder<Device, Device, QAfterFilterCondition> historyElement(
      FilterQuery<SubscriptionHistory> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'history');
    });
  }
}

extension DeviceQueryLinks on QueryBuilder<Device, Device, QFilterCondition> {
  QueryBuilder<Device, Device, QAfterFilterCondition> category(
      FilterQuery<Category> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'category');
    });
  }

  QueryBuilder<Device, Device, QAfterFilterCondition> categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'category', 0, true, 0, true);
    });
  }
}

extension DeviceQuerySortBy on QueryBuilder<Device, Device, QSortBy> {
  QueryBuilder<Device, Device, QAfterSortBy> sortByBackupDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByBackupDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByCustomIconPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customIconPath', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByCustomIconPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customIconPath', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByCycleCalculationMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleCalculationMode', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByCycleCalculationModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleCalculationMode', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByCycleDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleDays', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByCycleDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleDays', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByCycleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleType', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByCycleTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleType', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByDailyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyCost', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByDailyCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyCost', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByDaysUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUsed', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByDaysUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUsed', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByExpectedLifeYears() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedLifeYears', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByExpectedLifeYearsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedLifeYears', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByHasReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReminder', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByHasReminderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReminder', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByIsAutoRenew() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAutoRenew', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByIsAutoRenewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAutoRenew', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByLastUsedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByLastUsedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByNextBillingDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByNextBillingDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByPeriodPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodPrice', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByPeriodPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodPrice', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByPlatform() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByPlatformDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByPurchaseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByRenewalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'renewalPrice', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByRenewalPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'renewalPrice', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByScrapDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrapDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByScrapDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrapDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortBySubscriptionDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionDueDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortBySubscriptionDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionDueDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByTotalAccumulatedPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAccumulatedPrice', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByTotalAccumulatedPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAccumulatedPrice', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByUsageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageCount', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByUsageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageCount', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByWarrantyEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyEndDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> sortByWarrantyEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyEndDate', Sort.desc);
    });
  }
}

extension DeviceQuerySortThenBy on QueryBuilder<Device, Device, QSortThenBy> {
  QueryBuilder<Device, Device, QAfterSortBy> thenByBackupDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByBackupDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'backupDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByCustomIconPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customIconPath', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByCustomIconPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customIconPath', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByCycleCalculationMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleCalculationMode', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByCycleCalculationModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleCalculationMode', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByCycleDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleDays', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByCycleDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleDays', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByCycleType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleType', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByCycleTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleType', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByDailyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyCost', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByDailyCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyCost', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByDaysUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUsed', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByDaysUsedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'daysUsed', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByExpectedLifeYears() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedLifeYears', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByExpectedLifeYearsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedLifeYears', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByHasReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReminder', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByHasReminderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'hasReminder', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByImagePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByImagePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'imagePath', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByIsAutoRenew() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAutoRenew', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByIsAutoRenewDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isAutoRenew', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByLastUsedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByLastUsedDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUsedDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByNextBillingDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByNextBillingDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextBillingDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByPeriodPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodPrice', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByPeriodPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'periodPrice', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByPlatform() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByPlatformDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'platform', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByPurchaseDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'purchaseDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByRenewalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'renewalPrice', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByRenewalPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'renewalPrice', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByScrapDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrapDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByScrapDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scrapDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenBySubscriptionDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionDueDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenBySubscriptionDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'subscriptionDueDate', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByTotalAccumulatedPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAccumulatedPrice', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByTotalAccumulatedPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalAccumulatedPrice', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByUsageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageCount', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByUsageCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'usageCount', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByWarrantyEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyEndDate', Sort.asc);
    });
  }

  QueryBuilder<Device, Device, QAfterSortBy> thenByWarrantyEndDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warrantyEndDate', Sort.desc);
    });
  }
}

extension DeviceQueryWhereDistinct on QueryBuilder<Device, Device, QDistinct> {
  QueryBuilder<Device, Device, QDistinct> distinctByBackupDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'backupDate');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByCustomIconPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customIconPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByCycleCalculationMode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cycleCalculationMode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByCycleDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cycleDays');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByCycleType(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cycleType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByDailyCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyCost');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByDaysUsed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'daysUsed');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByExpectedLifeYears() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expectedLifeYears');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByHasReminder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'hasReminder');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByImagePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByIsAutoRenew() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isAutoRenew');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByLastUsedDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUsedDate');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByNextBillingDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextBillingDate');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByPeriodPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'periodPrice');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByPlatform(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'platform', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByPurchaseDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'purchaseDate');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByRenewalPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'renewalPrice');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByScrapDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scrapDate');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctBySubscriptionDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'subscriptionDueDate');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByTotalAccumulatedPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalAccumulatedPrice');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByUsageCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'usageCount');
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Device, Device, QDistinct> distinctByWarrantyEndDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'warrantyEndDate');
    });
  }
}

extension DeviceQueryProperty on QueryBuilder<Device, Device, QQueryProperty> {
  QueryBuilder<Device, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Device, DateTime?, QQueryOperations> backupDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'backupDate');
    });
  }

  QueryBuilder<Device, String?, QQueryOperations> customIconPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customIconPath');
    });
  }

  QueryBuilder<Device, CycleCalculationMode, QQueryOperations>
      cycleCalculationModeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cycleCalculationMode');
    });
  }

  QueryBuilder<Device, int?, QQueryOperations> cycleDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cycleDays');
    });
  }

  QueryBuilder<Device, CycleType?, QQueryOperations> cycleTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cycleType');
    });
  }

  QueryBuilder<Device, double, QQueryOperations> dailyCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyCost');
    });
  }

  QueryBuilder<Device, int, QQueryOperations> daysUsedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'daysUsed');
    });
  }

  QueryBuilder<Device, double?, QQueryOperations> expectedLifeYearsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expectedLifeYears');
    });
  }

  QueryBuilder<Device, bool, QQueryOperations> hasReminderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'hasReminder');
    });
  }

  QueryBuilder<Device, List<SubscriptionHistory>, QQueryOperations>
      historyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'history');
    });
  }

  QueryBuilder<Device, String?, QQueryOperations> imagePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePath');
    });
  }

  QueryBuilder<Device, bool, QQueryOperations> isAutoRenewProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isAutoRenew');
    });
  }

  QueryBuilder<Device, DateTime?, QQueryOperations> lastUsedDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUsedDate');
    });
  }

  QueryBuilder<Device, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Device, DateTime?, QQueryOperations> nextBillingDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextBillingDate');
    });
  }

  QueryBuilder<Device, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<Device, double?, QQueryOperations> periodPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'periodPrice');
    });
  }

  QueryBuilder<Device, String?, QQueryOperations> platformProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'platform');
    });
  }

  QueryBuilder<Device, double, QQueryOperations> priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<Device, DateTime, QQueryOperations> purchaseDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'purchaseDate');
    });
  }

  QueryBuilder<Device, double?, QQueryOperations> renewalPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'renewalPrice');
    });
  }

  QueryBuilder<Device, DateTime?, QQueryOperations> scrapDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scrapDate');
    });
  }

  QueryBuilder<Device, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<Device, DateTime?, QQueryOperations>
      subscriptionDueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'subscriptionDueDate');
    });
  }

  QueryBuilder<Device, List<String>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<Device, double, QQueryOperations>
      totalAccumulatedPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalAccumulatedPrice');
    });
  }

  QueryBuilder<Device, int, QQueryOperations> usageCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'usageCount');
    });
  }

  QueryBuilder<Device, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<Device, DateTime?, QQueryOperations> warrantyEndDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'warrantyEndDate');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const SubscriptionHistorySchema = Schema(
  name: r'SubscriptionHistory',
  id: -2416113455756638784,
  properties: {
    r'cycleCalculationMode': PropertySchema(
      id: 0,
      name: r'cycleCalculationMode',
      type: IsarType.string,
      enumMap: _SubscriptionHistorycycleCalculationModeEnumValueMap,
    ),
    r'cycleDays': PropertySchema(
      id: 1,
      name: r'cycleDays',
      type: IsarType.long,
    ),
    r'cycleType': PropertySchema(
      id: 2,
      name: r'cycleType',
      type: IsarType.string,
      enumMap: _SubscriptionHistorycycleTypeEnumValueMap,
    ),
    r'endDate': PropertySchema(
      id: 3,
      name: r'endDate',
      type: IsarType.dateTime,
    ),
    r'isAutoRenew': PropertySchema(
      id: 4,
      name: r'isAutoRenew',
      type: IsarType.bool,
    ),
    r'note': PropertySchema(
      id: 5,
      name: r'note',
      type: IsarType.string,
    ),
    r'price': PropertySchema(
      id: 6,
      name: r'price',
      type: IsarType.double,
    ),
    r'recordDate': PropertySchema(
      id: 7,
      name: r'recordDate',
      type: IsarType.dateTime,
    ),
    r'startDate': PropertySchema(
      id: 8,
      name: r'startDate',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _subscriptionHistoryEstimateSize,
  serialize: _subscriptionHistorySerialize,
  deserialize: _subscriptionHistoryDeserialize,
  deserializeProp: _subscriptionHistoryDeserializeProp,
);

int _subscriptionHistoryEstimateSize(
  SubscriptionHistory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cycleCalculationMode.name.length * 3;
  bytesCount += 3 + object.cycleType.name.length * 3;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _subscriptionHistorySerialize(
  SubscriptionHistory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cycleCalculationMode.name);
  writer.writeLong(offsets[1], object.cycleDays);
  writer.writeString(offsets[2], object.cycleType.name);
  writer.writeDateTime(offsets[3], object.endDate);
  writer.writeBool(offsets[4], object.isAutoRenew);
  writer.writeString(offsets[5], object.note);
  writer.writeDouble(offsets[6], object.price);
  writer.writeDateTime(offsets[7], object.recordDate);
  writer.writeDateTime(offsets[8], object.startDate);
}

SubscriptionHistory _subscriptionHistoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SubscriptionHistory();
  object.cycleCalculationMode =
      _SubscriptionHistorycycleCalculationModeValueEnumMap[
              reader.readStringOrNull(offsets[0])] ??
          CycleCalculationMode.calendar;
  object.cycleDays = reader.readLongOrNull(offsets[1]);
  object.cycleType = _SubscriptionHistorycycleTypeValueEnumMap[
          reader.readStringOrNull(offsets[2])] ??
      CycleType.daily;
  object.endDate = reader.readDateTimeOrNull(offsets[3]);
  object.isAutoRenew = reader.readBool(offsets[4]);
  object.note = reader.readStringOrNull(offsets[5]);
  object.price = reader.readDouble(offsets[6]);
  object.recordDate = reader.readDateTimeOrNull(offsets[7]);
  object.startDate = reader.readDateTimeOrNull(offsets[8]);
  return object;
}

P _subscriptionHistoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (_SubscriptionHistorycycleCalculationModeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          CycleCalculationMode.calendar) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (_SubscriptionHistorycycleTypeValueEnumMap[
              reader.readStringOrNull(offset)] ??
          CycleType.daily) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 8:
      return (reader.readDateTimeOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _SubscriptionHistorycycleCalculationModeEnumValueMap = {
  r'calendar': r'calendar',
  r'fixedDays': r'fixedDays',
};
const _SubscriptionHistorycycleCalculationModeValueEnumMap = {
  r'calendar': CycleCalculationMode.calendar,
  r'fixedDays': CycleCalculationMode.fixedDays,
};
const _SubscriptionHistorycycleTypeEnumValueMap = {
  r'daily': r'daily',
  r'weekly': r'weekly',
  r'monthly': r'monthly',
  r'quarterly': r'quarterly',
  r'halfYearly': r'halfYearly',
  r'yearly': r'yearly',
  r'oneTime': r'oneTime',
};
const _SubscriptionHistorycycleTypeValueEnumMap = {
  r'daily': CycleType.daily,
  r'weekly': CycleType.weekly,
  r'monthly': CycleType.monthly,
  r'quarterly': CycleType.quarterly,
  r'halfYearly': CycleType.halfYearly,
  r'yearly': CycleType.yearly,
  r'oneTime': CycleType.oneTime,
};

extension SubscriptionHistoryQueryFilter on QueryBuilder<SubscriptionHistory,
    SubscriptionHistory, QFilterCondition> {
  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleCalculationModeEqualTo(
    CycleCalculationMode value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleCalculationModeGreaterThan(
    CycleCalculationMode value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleCalculationModeLessThan(
    CycleCalculationMode value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleCalculationModeBetween(
    CycleCalculationMode lower,
    CycleCalculationMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cycleCalculationMode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleCalculationModeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleCalculationModeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleCalculationModeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cycleCalculationMode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleCalculationModeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cycleCalculationMode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleCalculationModeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleCalculationMode',
        value: '',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleCalculationModeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cycleCalculationMode',
        value: '',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleDaysIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cycleDays',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleDaysIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cycleDays',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleDaysEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleDays',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleDaysGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cycleDays',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleDaysLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cycleDays',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleDaysBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cycleDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleTypeEqualTo(
    CycleType value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleTypeGreaterThan(
    CycleType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleTypeLessThan(
    CycleType value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleTypeBetween(
    CycleType lower,
    CycleType upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cycleType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cycleType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cycleType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleType',
        value: '',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      cycleTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cycleType',
        value: '',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      endDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      endDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'endDate',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      endDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      endDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      endDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'endDate',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      endDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'endDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      isAutoRenewEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isAutoRenew',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      priceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      priceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      priceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      priceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      recordDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'recordDate',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      recordDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'recordDate',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      recordDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'recordDate',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      recordDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'recordDate',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      recordDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'recordDate',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      recordDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'recordDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      startDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      startDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      startDateEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      startDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      startDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<SubscriptionHistory, SubscriptionHistory, QAfterFilterCondition>
      startDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SubscriptionHistoryQueryObject on QueryBuilder<SubscriptionHistory,
    SubscriptionHistory, QFilterCondition> {}
