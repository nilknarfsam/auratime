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
    expect(engine.getDayType(saturday), WorkDayType.compensatoryDayOff);
    expect(engine.calculateExpectedDuration(saturday), Duration.zero);
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

  test('Saturday without explicit rule is non-working day', () {
    final engine = WorkScheduleEngine(WorkDayRule.defaults());
    final saturday = DateTime(2026, 5, 2);
    expect(engine.getDayType(saturday), WorkDayType.compensatoryDayOff);
    expect(engine.calculateExpectedDuration(saturday), Duration.zero);
    expect(engine.isWorkingDay(saturday), isFalse);
  });

  test('Sunday without explicit rule is non-working day', () {
    final engine = WorkScheduleEngine(WorkDayRule.defaults());
    final sunday = DateTime(2026, 5, 3);
    expect(engine.getDayType(sunday), WorkDayType.compensatoryDayOff);
    expect(engine.calculateExpectedDuration(sunday), Duration.zero);
    expect(engine.isWorkingDay(sunday), isFalse);
  });

  test('Saturday with compensation rule uses 07:00 to 15:00', () {
    final saturday = DateTime(2026, 5, 2);
    final rule = WorkDayRule.defaults().copyWith(
      companyCalendarRules: [
        CompanyCalendarRule(
          date: saturday,
          dayType: WorkDayType.saturdayCompensation,
          note: 'Compensacao oficial',
        ),
      ],
    );
    final engine = WorkScheduleEngine(rule);
    final shift = engine.getShiftForDate(saturday);
    expect(engine.getDayType(saturday), WorkDayType.saturdayCompensation);
    expect(engine.isWorkingDay(saturday), isTrue);
    expect(shift, isNotNull);
    expect(shift!.startHour, 7);
    expect(shift.startMinute, 0);
    expect(shift.endHour, 15);
    expect(shift.endMinute, 0);
    expect(engine.calculateExpectedDuration(saturday), const Duration(hours: 8));
  });

  test('Sunday with explicit worked rule is a working day', () {
    final sunday = DateTime(2026, 5, 3);
    final rule = WorkDayRule.defaults().copyWith(
      companyCalendarRules: [
        CompanyCalendarRule(
          date: sunday,
          dayType: WorkDayType.holidayWorkedSwap,
          note: 'Plantao extraordinario',
        ),
      ],
    );
    final engine = WorkScheduleEngine(rule);
    expect(engine.getDayType(sunday), WorkDayType.holidayWorkedSwap);
    expect(engine.isWorkingDay(sunday), isTrue);
    expect(
      engine.calculateExpectedDuration(sunday),
      const Duration(hours: 9, minutes: 48),
    );
  });

  test('Weekend without punch has no negative expectation', () {
    final engine = WorkScheduleEngine(WorkDayRule.defaults());
    final saturday = DateTime(2026, 5, 2);
    final sunday = DateTime(2026, 5, 3);
    expect(engine.calculateExpectedDuration(saturday), Duration.zero);
    expect(engine.calculateExpectedDuration(sunday), Duration.zero);
  });

  test('Saturday default off renders Folga', () {
    final engine = WorkScheduleEngine(WorkDayRule.defaults());
    expect(engine.getDisplayDayLabel(DateTime(2026, 5, 2)), 'Folga');
  });

  test('Sunday default off renders Folga', () {
    final engine = WorkScheduleEngine(WorkDayRule.defaults());
    expect(engine.getDisplayDayLabel(DateTime(2026, 5, 3)), 'Folga');
  });

  test('Explicit compensatory day off renders Folga compensatória', () {
    final targetDate = DateTime(2026, 5, 9);
    final engine = WorkScheduleEngine(
      WorkDayRule.defaults().copyWith(
        companyCalendarRules: [
          CompanyCalendarRule(
            date: targetDate,
            dayType: WorkDayType.compensatoryDayOff,
            note: 'Folga por compensacao',
          ),
        ],
      ),
    );
    expect(engine.getDisplayDayLabel(targetDate), 'Folga compensatória');
  });

  test('Backward compatibility defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppSettingsService.initialize();
    expect(AppSettingsService.current.workDayRule.defaultShiftType, ShiftType.firstCommercial);
    expect(AppSettingsService.current.workDayRule.holidays, isEmpty);
    expect(AppSettingsService.current.workDayRule.companyCalendarRules, isEmpty);
  });
}
