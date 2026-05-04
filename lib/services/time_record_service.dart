import 'package:auratime/models/time_record.dart';
import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

enum PunchRecordStatus { checkInRecorded, checkOutRecorded, dayFinalized }

class PunchRecordResult {
  const PunchRecordResult({required this.status, required this.record});

  final PunchRecordStatus status;
  final TimeRecord record;
}

class TimeRecordService {
  static Isar? _isar;

  static Future<void> initialize() async {
    if (_isar != null) {
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [TimeRecordSchema],
      directory: directory.path,
      name: 'auratime_db',
    );
  }

  Future<TimeRecord> getTodayRecord({DateTime? date}) async {
    final isar = _getIsar();
    final day = _normalizeDate(date ?? DateTime.now());
    final existing = await isar.timeRecords
        .where()
        .dateEqualTo(day)
        .findFirst();
    return existing ?? TimeRecord.forDate(day);
  }

  Future<List<TimeRecord>> getAllRecords() async {
    final isar = _getIsar();
    final records = await isar.timeRecords.where().findAll();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<Duration> calculateTotalBalance() async {
    final records = await getAllRecords();
    Duration total = Duration.zero;
    for (final record in records) {
      total += record.balance;
    }
    return total;
  }

  Future<TimeRecord> fillWithDefaultSchedule({DateTime? date}) async {
    final dayRecord = await getTodayRecord(date: date);
    final day = _normalizeDate(date ?? DateTime.now());
    final settings = AppSettingsService.current;
    final engine = WorkScheduleEngine(settings.workDayRule);
    final shift = engine.getShiftForDate(day);
    if (shift == null) {
      dayRecord.date = day;
      dayRecord.entryTime = null;
      dayRecord.exitTime = null;
      await _saveRecord(dayRecord);
      return dayRecord;
    }

    dayRecord.date = day;
    dayRecord.entryTime = _timeForDay(day, shift.startHour, shift.startMinute);
    final exitBase = shift.isOvernight ? day.add(const Duration(days: 1)) : day;
    dayRecord.exitTime = _timeForDay(exitBase, shift.endHour, shift.endMinute);

    await _saveRecord(dayRecord);
    return dayRecord;
  }

  Future<PunchRecordResult> recordCurrentTime({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final overnightOpenRecord = await _getOpenOvernightRecord(currentTime);
    final dayRecord =
        overnightOpenRecord ?? await getTodayRecord(date: currentTime);

    if (dayRecord.entryTime == null) {
      dayRecord.entryTime = currentTime;
      await _saveRecord(dayRecord);
      return PunchRecordResult(
        status: PunchRecordStatus.checkInRecorded,
        record: dayRecord,
      );
    }

    if (dayRecord.exitTime == null) {
      dayRecord.exitTime = currentTime;
      await _saveRecord(dayRecord);
      return PunchRecordResult(
        status: PunchRecordStatus.checkOutRecorded,
        record: dayRecord,
      );
    }

    return PunchRecordResult(
      status: PunchRecordStatus.dayFinalized,
      record: dayRecord,
    );
  }

  Future<TimeRecord> saveRecord(TimeRecord record) async {
    await _saveRecord(record);
    return record;
  }

  Future<void> _saveRecord(TimeRecord record) async {
    final isar = _getIsar();
    await isar.writeTxn(() async {
      await isar.timeRecords.put(record);
    });
  }

  Future<void> upsertRecordByDate(TimeRecord record) async {
    final isar = _getIsar();
    final normalizedDate = _normalizeDate(record.date);
    await isar.writeTxn(() async {
      final existing = await isar.timeRecords
          .where()
          .dateEqualTo(normalizedDate)
          .findFirst();
      if (existing != null) {
        record.id = existing.id;
      } else {
        record.id = Isar.autoIncrement;
      }
      record.date = normalizedDate;
      await isar.timeRecords.put(record);
    });
  }

  Isar _getIsar() {
    final isar = _isar;
    if (isar == null) {
      throw StateError(
        'Isar não foi inicializado. Chame TimeRecordService.initialize() no main().',
      );
    }
    return isar;
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _timeForDay(DateTime date, int hour, int minute) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Future<TimeRecord?> _getOpenOvernightRecord(DateTime currentTime) async {
    final yesterday = _normalizeDate(
      currentTime.subtract(const Duration(days: 1)),
    );
    final record = await getTodayRecord(date: yesterday);
    if (record.entryTime == null || record.exitTime != null) {
      return null;
    }
    final engine = WorkScheduleEngine(AppSettingsService.current.workDayRule);
    final shift = engine.getShiftForDate(yesterday);
    if (shift == null || !shift.isOvernight) {
      return null;
    }
    final expectedExit = engine.calculateExpectedExit(yesterday, record.entryTime!);
    if (expectedExit == null) {
      return null;
    }
    final maxWindow = expectedExit.add(const Duration(hours: 8));
    if (currentTime.isAfter(maxWindow)) {
      return null;
    }
    return record;
  }
}
