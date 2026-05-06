import 'package:auratime/domain/work_schedule/work_day_accounting.dart';
import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WorkDayAccounting', () {
    test('expectedNetWork subtracts lunch from gross', () {
      expect(
        WorkDayAccounting.expectedNetWork(
          grossShiftDuration: const Duration(hours: 9, minutes: 48),
          lunchBreak: const Duration(hours: 1),
        ),
        const Duration(hours: 8, minutes: 48),
      );
    });

    test('expectedNetWork clamps at zero when lunch exceeds gross', () {
      expect(
        WorkDayAccounting.expectedNetWork(
          grossShiftDuration: const Duration(minutes: 30),
          lunchBreak: const Duration(hours: 1),
        ),
        Duration.zero,
      );
    });

    test('progress01 reaches 1 when net worked meets net expected', () {
      expect(
        WorkDayAccounting.progress01(
          workedNet: const Duration(hours: 8, minutes: 52),
          expectedNet: const Duration(hours: 8, minutes: 48),
        ),
        1.0,
      );
    });
  });

  group('balance and progress integration', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await AppSettingsService.initialize();
    });

    test('early check-in: balance positive not negative at 16:43 exit', () async {
      final day = DateTime(2026, 5, 4);
      final record = TimeRecord.forDate(
        day,
        entryTime: DateTime(2026, 5, 4, 6, 51),
        exitTime: DateTime(2026, 5, 4, 16, 43),
      );
      expect(record.balance, const Duration(minutes: 4));

      final engine = WorkScheduleEngine(AppSettingsService.current.workDayRule);
      final gross = engine.calculateExpectedDuration(day);
      final netExpected = WorkDayAccounting.expectedNetWork(
        grossShiftDuration: gross,
        lunchBreak: AppSettingsService.current.lunchBreakDuration,
      );
      final worked = WorkDayAccounting.workedNetSession(
        entry: record.entryTime,
        exit: record.exitTime,
        now: DateTime(2026, 5, 4, 18, 0),
        lunchBreak: AppSettingsService.current.lunchBreakDuration,
      );
      expect(
        WorkDayAccounting.progress01(workedNet: worked, expectedNet: netExpected),
        1.0,
      );
    });

    test('exact nominal gross window yields zero balance and full progress', () {
      final day = DateTime(2026, 5, 4);
      final record = TimeRecord.forDate(
        day,
        entryTime: DateTime(2026, 5, 4, 7, 0),
        exitTime: DateTime(2026, 5, 4, 16, 48),
      );
      expect(record.balance, Duration.zero);

      final engine = WorkScheduleEngine(AppSettingsService.current.workDayRule);
      final netExpected = WorkDayAccounting.expectedNetWork(
        grossShiftDuration: engine.calculateExpectedDuration(day),
        lunchBreak: AppSettingsService.current.lunchBreakDuration,
      );
      final worked = WorkDayAccounting.workedNetSession(
        entry: record.entryTime,
        exit: record.exitTime,
        now: DateTime(2026, 5, 4, 18, 0),
        lunchBreak: AppSettingsService.current.lunchBreakDuration,
      );
      expect(
        WorkDayAccounting.progress01(workedNet: worked, expectedNet: netExpected),
        1.0,
      );
    });

    test('overtime after nominal exit increases balance', () {
      final day = DateTime(2026, 5, 4);
      final record = TimeRecord.forDate(
        day,
        entryTime: DateTime(2026, 5, 4, 7, 0),
        exitTime: DateTime(2026, 5, 4, 17, 48),
      );
      expect(record.balance.inMinutes, 60);
    });

    test('second commercial shift expected net is gross minus lunch', () {
      final rule = WorkDayRule.defaults().copyWith(defaultShiftType: ShiftType.secondCommercial);
      final engine = WorkScheduleEngine(rule);
      final day = DateTime(2026, 5, 4);
      final gross = engine.calculateExpectedDuration(day);
      expect(gross, const Duration(hours: 9, minutes: 13));
      final net = WorkDayAccounting.expectedNetWork(
        grossShiftDuration: gross,
        lunchBreak: const Duration(hours: 1),
      );
      expect(net, const Duration(hours: 8, minutes: 13));
    });

    test('saturday compensation eight hours gross yields net minus lunch', () {
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
      final gross = engine.calculateExpectedDuration(saturday);
      expect(gross, const Duration(hours: 8));
      final net = WorkDayAccounting.expectedNetWork(
        grossShiftDuration: gross,
        lunchBreak: const Duration(hours: 1),
      );
      expect(net, const Duration(hours: 7));
    });
  });
}
