import 'package:auratime/domain/insights/insights_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/models/time_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('late pattern detection', () {
    final records = <TimeRecord>[];
    for (int i = 0; i < 6; i++) {
      records.add(
        TimeRecord.forDate(
          DateTime(2026, 5, 1 + i),
          entryTime: DateTime(2026, 5, 1 + i, 7, 30),
          exitTime: DateTime(2026, 5, 1 + i, 17, 30),
        ),
      );
    }
    final engine = InsightsEngine(
      workScheduleEngine: WorkScheduleEngine(WorkDayRule.defaults()),
    );
    final insights = engine.analyze(records: records, now: DateTime(2026, 5, 7));
    expect(
      insights.any((i) => i.message.contains('entradas com atraso')),
      isTrue,
    );
  });

  test('overtime detection', () {
    final records = <TimeRecord>[];
    for (int i = 0; i < 5; i++) {
      records.add(
        TimeRecord.forDate(
          DateTime(2026, 5, 1 + i),
          entryTime: DateTime(2026, 5, 1 + i, 7, 0),
          exitTime: DateTime(2026, 5, 1 + i, 18, 30),
        ),
      );
    }
    final engine = InsightsEngine(
      workScheduleEngine: WorkScheduleEngine(WorkDayRule.defaults()),
    );
    final insights = engine.analyze(records: records, now: DateTime(2026, 5, 7));
    expect(
      insights.any((i) => i.message.contains('hora extra')),
      isTrue,
    );
  });

  test('empty data handling', () {
    final engine = InsightsEngine(
      workScheduleEngine: WorkScheduleEngine(WorkDayRule.defaults()),
    );
    final insights = engine.analyze(records: const [], now: DateTime(2026, 5, 7));
    expect(insights, isNotEmpty);
    expect(insights.first.message, contains('Sem dados suficientes'));
  });
}
