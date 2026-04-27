// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'time_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTimeRecordCollection on Isar {
  IsarCollection<TimeRecord> get timeRecords => this.collection();
}

const TimeRecordSchema = CollectionSchema(
  name: r'TimeRecord',
  id: -6437961634876736518,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'dayType': PropertySchema(
      id: 1,
      name: r'dayType',
      type: IsarType.byte,
      enumMap: _TimeRecorddayTypeEnumValueMap,
    ),
    r'entryTime': PropertySchema(
      id: 2,
      name: r'entryTime',
      type: IsarType.dateTime,
    ),
    r'exitTime': PropertySchema(
      id: 3,
      name: r'exitTime',
      type: IsarType.dateTime,
    ),
    r'note': PropertySchema(
      id: 4,
      name: r'note',
      type: IsarType.string,
    )
  },
  estimateSize: _timeRecordEstimateSize,
  serialize: _timeRecordSerialize,
  deserialize: _timeRecordDeserialize,
  deserializeProp: _timeRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'date': IndexSchema(
      id: -7552997827385218417,
      name: r'date',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'date',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _timeRecordGetId,
  getLinks: _timeRecordGetLinks,
  attach: _timeRecordAttach,
  version: '3.1.0+1',
);

int _timeRecordEstimateSize(
  TimeRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.note;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _timeRecordSerialize(
  TimeRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeByte(offsets[1], object.dayType.index);
  writer.writeDateTime(offsets[2], object.entryTime);
  writer.writeDateTime(offsets[3], object.exitTime);
  writer.writeString(offsets[4], object.note);
}

TimeRecord _timeRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimeRecord(
    entryTime: reader.readDateTimeOrNull(offsets[2]),
    exitTime: reader.readDateTimeOrNull(offsets[3]),
  );
  object.date = reader.readDateTime(offsets[0]);
  object.dayType =
      _TimeRecorddayTypeValueEnumMap[reader.readByteOrNull(offsets[1])] ??
          DayType.regular;
  object.id = id;
  object.note = reader.readStringOrNull(offsets[4]);
  return object;
}

P _timeRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (_TimeRecorddayTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          DayType.regular) as P;
    case 2:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TimeRecorddayTypeEnumValueMap = {
  'regular': 0,
  'holiday': 1,
  'dayOff': 2,
};
const _TimeRecorddayTypeValueEnumMap = {
  0: DayType.regular,
  1: DayType.holiday,
  2: DayType.dayOff,
};

Id _timeRecordGetId(TimeRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _timeRecordGetLinks(TimeRecord object) {
  return [];
}

void _timeRecordAttach(IsarCollection<dynamic> col, Id id, TimeRecord object) {
  object.id = id;
}

extension TimeRecordByIndex on IsarCollection<TimeRecord> {
  Future<TimeRecord?> getByDate(DateTime date) {
    return getByIndex(r'date', [date]);
  }

  TimeRecord? getByDateSync(DateTime date) {
    return getByIndexSync(r'date', [date]);
  }

  Future<bool> deleteByDate(DateTime date) {
    return deleteByIndex(r'date', [date]);
  }

  bool deleteByDateSync(DateTime date) {
    return deleteByIndexSync(r'date', [date]);
  }

  Future<List<TimeRecord?>> getAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndex(r'date', values);
  }

  List<TimeRecord?> getAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'date', values);
  }

  Future<int> deleteAllByDate(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'date', values);
  }

  int deleteAllByDateSync(List<DateTime> dateValues) {
    final values = dateValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'date', values);
  }

  Future<Id> putByDate(TimeRecord object) {
    return putByIndex(r'date', object);
  }

  Id putByDateSync(TimeRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'date', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDate(List<TimeRecord> objects) {
    return putAllByIndex(r'date', objects);
  }

  List<Id> putAllByDateSync(List<TimeRecord> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'date', objects, saveLinks: saveLinks);
  }
}

extension TimeRecordQueryWhereSort
    on QueryBuilder<TimeRecord, TimeRecord, QWhere> {
  QueryBuilder<TimeRecord, TimeRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterWhere> anyDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'date'),
      );
    });
  }
}

extension TimeRecordQueryWhere
    on QueryBuilder<TimeRecord, TimeRecord, QWhereClause> {
  QueryBuilder<TimeRecord, TimeRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterWhereClause> idBetween(
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterWhereClause> dateEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'date',
        value: [date],
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterWhereClause> dateNotEqualTo(
      DateTime date) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [date],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'date',
              lower: [],
              upper: [date],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterWhereClause> dateGreaterThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [date],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterWhereClause> dateLessThan(
    DateTime date, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [],
        upper: [date],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterWhereClause> dateBetween(
    DateTime lowerDate,
    DateTime upperDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'date',
        lower: [lowerDate],
        includeLower: includeLower,
        upper: [upperDate],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TimeRecordQueryFilter
    on QueryBuilder<TimeRecord, TimeRecord, QFilterCondition> {
  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> dayTypeEqualTo(
      DayType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayType',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      dayTypeGreaterThan(
    DayType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayType',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> dayTypeLessThan(
    DayType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayType',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> dayTypeBetween(
    DayType lower,
    DayType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      entryTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'entryTime',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      entryTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'entryTime',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> entryTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'entryTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      entryTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'entryTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> entryTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'entryTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> entryTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'entryTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> exitTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'exitTime',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      exitTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'exitTime',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> exitTimeEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'exitTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      exitTimeGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'exitTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> exitTimeLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'exitTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> exitTimeBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'exitTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> idBetween(
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'note',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteEqualTo(
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteGreaterThan(
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteLessThan(
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteBetween(
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteStartsWith(
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteEndsWith(
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

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }
}

extension TimeRecordQueryObject
    on QueryBuilder<TimeRecord, TimeRecord, QFilterCondition> {}

extension TimeRecordQueryLinks
    on QueryBuilder<TimeRecord, TimeRecord, QFilterCondition> {}

extension TimeRecordQuerySortBy
    on QueryBuilder<TimeRecord, TimeRecord, QSortBy> {
  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> sortByDayType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayType', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> sortByDayTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayType', Sort.desc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> sortByEntryTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryTime', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> sortByEntryTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryTime', Sort.desc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> sortByExitTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exitTime', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> sortByExitTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exitTime', Sort.desc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }
}

extension TimeRecordQuerySortThenBy
    on QueryBuilder<TimeRecord, TimeRecord, QSortThenBy> {
  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByDayType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayType', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByDayTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayType', Sort.desc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByEntryTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryTime', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByEntryTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryTime', Sort.desc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByExitTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exitTime', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByExitTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'exitTime', Sort.desc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }
}

extension TimeRecordQueryWhereDistinct
    on QueryBuilder<TimeRecord, TimeRecord, QDistinct> {
  QueryBuilder<TimeRecord, TimeRecord, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QDistinct> distinctByDayType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayType');
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QDistinct> distinctByEntryTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entryTime');
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QDistinct> distinctByExitTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'exitTime');
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }
}

extension TimeRecordQueryProperty
    on QueryBuilder<TimeRecord, TimeRecord, QQueryProperty> {
  QueryBuilder<TimeRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TimeRecord, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<TimeRecord, DayType, QQueryOperations> dayTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayType');
    });
  }

  QueryBuilder<TimeRecord, DateTime?, QQueryOperations> entryTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryTime');
    });
  }

  QueryBuilder<TimeRecord, DateTime?, QQueryOperations> exitTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'exitTime');
    });
  }

  QueryBuilder<TimeRecord, String?, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }
}
