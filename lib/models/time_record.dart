import 'package:isar/isar.dart';

part 'time_record.g.dart';

enum DayType { regular, holiday, dayOff }

@collection
class TimeRecord {
  static const Duration dailyGoal = Duration(hours: 8, minutes: 48);

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
    if (entryTime != null && exitTime != null && exitTime!.isAfter(entryTime!)) {
      final grossDuration = exitTime!.difference(entryTime!);
      if (grossDuration <= const Duration(hours: 1)) {
        return Duration.zero;
      }
      return grossDuration - const Duration(hours: 1);
    }
    return Duration.zero;
  }

  @ignore
  Duration get balance {
    if (dayType == DayType.holiday) {
      return Duration.zero;
    }
    if (dayType == DayType.dayOff) {
      if (totalWorkedHours == Duration.zero) {
        return -dailyGoal;
      }
      return totalWorkedHours - dailyGoal;
    }
    if (totalWorkedHours == Duration.zero) {
      return Duration.zero;
    }
    return totalWorkedHours - dailyGoal;
  }

  @ignore
  DateTime? get predictedExitTime {
    if (entryTime == null) {
      return null;
    }
    return entryTime!.add(const Duration(hours: 9, minutes: 48));
  }

  @ignore
  bool get hasNote => note != null && note!.trim().isNotEmpty;

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
