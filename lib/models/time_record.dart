import 'package:isar/isar.dart';

part 'time_record.g.dart';

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
  DateTime? entryTime;
  DateTime? exitTime;

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
    if (totalWorkedHours == Duration.zero) {
      return Duration.zero;
    }
    return totalWorkedHours - dailyGoal;
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
