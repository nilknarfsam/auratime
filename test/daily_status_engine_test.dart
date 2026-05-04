import 'package:auratime/domain/work_schedule/daily_status_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/models/time_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Working day before start', () {
    final date = DateTime(2026, 5, 4);
    final engine = DailyStatusEngine(
      workScheduleEngine: WorkScheduleEngine(WorkDayRule.defaults()),
    );
    final result = engine.evaluate(
      now: DateTime(2026, 5, 4, 6, 30),
      todayRecord: TimeRecord.forDate(date),
    );
    expect(result.statusType, DailyStatusType.beforeStart);
  });

  test('Working day in progress', () {
    final date = DateTime(2026, 5, 4);
    final record = TimeRecord.forDate(
      date,
      entryTime: DateTime(2026, 5, 4, 7, 0),
    );
    final engine = DailyStatusEngine(
      workScheduleEngine: WorkScheduleEngine(WorkDayRule.defaults()),
    );
    final result = engine.evaluate(
      now: DateTime(2026, 5, 4, 10, 0),
      todayRecord: record,
    );
    expect(result.statusType, DailyStatusType.working);
  });

  test('Completed day', () {
    final date = DateTime(2026, 5, 4);
    final record = TimeRecord.forDate(
      date,
      entryTime: DateTime(2026, 5, 4, 7, 0),
      exitTime: DateTime(2026, 5, 4, 17, 48),
    );
    final engine = DailyStatusEngine(
      workScheduleEngine: WorkScheduleEngine(WorkDayRule.defaults()),
    );
    final result = engine.evaluate(
      now: DateTime(2026, 5, 4, 18, 0),
      todayRecord: record,
    );
    expect(result.statusType, DailyStatusType.completed);
  });

  test('Overtime', () {
    final date = DateTime(2026, 5, 4);
    final record = TimeRecord.forDate(
      date,
      entryTime: DateTime(2026, 5, 4, 7, 0),
    );
    final engine = DailyStatusEngine(
      workScheduleEngine: WorkScheduleEngine(WorkDayRule.defaults()),
    );
    final result = engine.evaluate(
      now: DateTime(2026, 5, 4, 18, 0),
      todayRecord: record,
    );
    expect(result.statusType, DailyStatusType.overtime);
  });

  test('Weekend off day', () {
    final date = DateTime(2026, 5, 3);
    final engine = DailyStatusEngine(
      workScheduleEngine: WorkScheduleEngine(WorkDayRule.defaults()),
    );
    final result = engine.evaluate(
      now: DateTime(2026, 5, 3, 9, 0),
      todayRecord: TimeRecord.forDate(date),
    );
    expect(result.statusType, DailyStatusType.offDay);
  });
}
