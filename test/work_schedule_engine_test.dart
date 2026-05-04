import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('First shift expected duration', () {
    final rule = WorkDayRule.defaults();
    final engine = WorkScheduleEngine(rule);
    expect(
      engine.calculateExpectedDuration(DateTime(2026, 5, 4)),
      const Duration(hours: 9, minutes: 48),
    );
  });

  test('Second shift crossing midnight', () {
    final rule = WorkDayRule.defaults().copyWith(defaultShiftType: ShiftType.secondCommercial);
    final engine = WorkScheduleEngine(rule);
    final checkIn = DateTime(2026, 5, 4, 16, 48);
    final expectedExit = engine.calculateExpectedExit(DateTime(2026, 5, 4), checkIn);
    expect(expectedExit, DateTime(2026, 5, 5, 2, 1));
  });

  test('Saturday compensation', () {
    final rule = WorkDayRule.defaults().copyWith(saturdayCompensationEnabled: true);
    final engine = WorkScheduleEngine(rule);
    final saturday = DateTime(2026, 5, 2);
    expect(engine.getDayType(saturday), WorkDayType.saturdayCompensation);
    expect(engine.calculateExpectedDuration(saturday), const Duration(hours: 8));
  });

  test('Holiday with zero expected hours', () {
    final holiday = Holiday(date: DateTime(2026, 12, 25), name: 'Natal');
    final rule = WorkDayRule.defaults().copyWith(holidays: [holiday]);
    final engine = WorkScheduleEngine(rule);
    expect(engine.getDayType(DateTime(2026, 12, 25)), WorkDayType.holiday);
    expect(engine.calculateExpectedDuration(DateTime(2026, 12, 25)), Duration.zero);
  });

  test('Holiday worked as regular day', () {
    final holiday = Holiday(date: DateTime(2026, 12, 25), name: 'Natal');
    final swap = CompanyCalendarRule(
      date: DateTime(2026, 12, 25),
      dayType: WorkDayType.holidayWorkedSwap,
      note: 'Troca oficial',
    );
    final rule = WorkDayRule.defaults().copyWith(holidays: [holiday], companyCalendarRules: [swap]);
    final engine = WorkScheduleEngine(rule);
    expect(engine.getDayType(DateTime(2026, 12, 25)), WorkDayType.holidayWorkedSwap);
    expect(
      engine.calculateExpectedDuration(DateTime(2026, 12, 25)),
      const Duration(hours: 9, minutes: 48),
    );
  });

  test('Compensatory day off', () {
    final rule = WorkDayRule.defaults().copyWith(
      companyCalendarRules: [
        CompanyCalendarRule(
          date: DateTime(2026, 5, 6),
          dayType: WorkDayType.compensatoryDayOff,
          note: 'Folga',
        ),
      ],
    );
    final engine = WorkScheduleEngine(rule);
    expect(engine.getDayType(DateTime(2026, 5, 6)), WorkDayType.compensatoryDayOff);
    expect(engine.isWorkingDay(DateTime(2026, 5, 6)), isFalse);
  });

  test('Backward compatibility defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppSettingsService.initialize();
    expect(AppSettingsService.current.workDayRule.defaultShiftType, ShiftType.firstCommercial);
    expect(AppSettingsService.current.workDayRule.holidays, isEmpty);
    expect(AppSettingsService.current.workDayRule.companyCalendarRules, isEmpty);
  });
}
