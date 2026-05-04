import 'package:isar/isar.dart';
import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/services/app_settings_service.dart';

part 'time_record.g.dart';

enum DayType { regular, holiday, dayOff }

@collection
class TimeRecord {
  TimeRecord({
    this.entryTime,
    this.exitTime,
  }) : date = _normalizeDate(DateTime.now());

  TimeRecord.forDate(
    DateTime date, {
    this.entryTime,
    this.exitTime,
  }) : date = _normalizeDate(date);

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  DateTime date;
  @enumerated
  DayType dayType = DayType.regular;
  DateTime? entryTime;
  DateTime? exitTime;
  String? note;

  @ignore
  Duration get totalWorkedHours {
    final lunchBreak = AppSettingsService.current.lunchBreakDuration;
    if (entryTime != null && exitTime != null && exitTime!.isAfter(entryTime!)) {
      final grossDuration = exitTime!.difference(entryTime!);
      if (grossDuration <= lunchBreak) {
        return Duration.zero;
      }
      return grossDuration - lunchBreak;
    }
    return Duration.zero;
  }

  @ignore
  Duration get balance {
    final settings = AppSettingsService.current;
    final engine = WorkScheduleEngine(settings.workDayRule);
    final expectedDuration = engine.calculateExpectedDuration(date);
    if (dayType == DayType.holiday) {
      return Duration.zero;
    }
    if (dayType == DayType.dayOff) {
      return totalWorkedHours;
    }
    if (totalWorkedHours == Duration.zero) {
      return Duration.zero;
    }
    return totalWorkedHours - expectedDuration;
  }

  @ignore
  DateTime? get predictedExitTime {
    if (entryTime == null) {
      return null;
    }
    final settings = AppSettingsService.current;
    final engine = WorkScheduleEngine(settings.workDayRule);
    return engine.calculateExpectedExit(date, entryTime!);
  }

  @ignore
  bool get hasNote => note != null && note!.trim().isNotEmpty;

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
