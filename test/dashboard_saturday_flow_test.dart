import 'package:auratime/domain/insights/insights_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/screens/dashboard_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Saturday classification prompt', () {
    test('Saturday without explicit rule prompts classification', () {
      final date = DateTime(2026, 5, 2);
      final engine = WorkScheduleEngine(WorkDayRule.defaults());

      final shouldPrompt = shouldPromptSaturdayClassification(
        date: date,
        engine: engine,
      );

      expect(shouldPrompt, isTrue);
    });

    test('Saturday with explicit rule does not prompt again', () {
      final date = DateTime(2026, 5, 2);
      final rule = WorkDayRule.defaults().copyWith(
        companyCalendarRules: [
          CompanyCalendarRule(
            date: date,
            dayType: WorkDayType.saturdayCompensation,
          ),
        ],
      );
      final engine = WorkScheduleEngine(rule);

      final shouldPrompt = shouldPromptSaturdayClassification(
        date: date,
        engine: engine,
      );

      expect(shouldPrompt, isFalse);
    });

    test('Choosing compensation creates saturdayCompensation rule', () {
      final saturday = DateTime(2026, 5, 2);
      final updatedRule = applySaturdayClassificationRule(
        baseRule: WorkDayRule.defaults(),
        date: saturday,
        dayType: WorkDayType.saturdayCompensation,
      );
      final engine = WorkScheduleEngine(updatedRule);

      expect(engine.getDayType(saturday), WorkDayType.saturdayCompensation);
      expect(engine.hasExplicitRuleForDate(saturday), isTrue);
    });
  });
}
