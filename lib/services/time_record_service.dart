import 'package:auratime/models/time_record.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

enum PunchRecordStatus { checkInRecorded, checkOutRecorded, dayFinalized }

class PunchRecordResult {
  const PunchRecordResult({
    required this.status,
    required this.record,
  });

  final PunchRecordStatus status;
  final TimeRecord record;
}

class TimeRecordService {
  static const int defaultEntryHour = 7;
  static const int defaultEntryMinute = 0;
  static const int defaultExitHour = 16;
  static const int defaultExitMinute = 48;

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
    final existing = await isar.timeRecords.where().dateEqualTo(day).findFirst();
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

    dayRecord.date = day;
    dayRecord.entryTime = _timeForDay(day, defaultEntryHour, defaultEntryMinute);
    dayRecord.exitTime = _timeForDay(day, defaultExitHour, defaultExitMinute);

    await _saveRecord(dayRecord);
    return dayRecord;
  }

  Future<PunchRecordResult> recordCurrentTime({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final dayRecord = await getTodayRecord(date: currentTime);

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

  Isar _getIsar() {
    final isar = _isar;
    if (isar == null) {
      throw StateError('Isar não foi inicializado. Chame TimeRecordService.initialize() no main().');
    }
    return isar;
  }

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _timeForDay(DateTime date, int hour, int minute) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
