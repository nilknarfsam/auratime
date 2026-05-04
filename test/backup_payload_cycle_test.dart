import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/models/backup_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BackupSettings falls back cycleStartDay to 1 when missing', () {
    final parsed = BackupSettings.fromJson(<String, dynamic>{
      'userName': 'Teste',
      'defaultEntryHour': 7,
      'defaultEntryMinute': 0,
      'defaultExitHour': 16,
      'defaultExitMinute': 48,
      'lunchBreakMinutes': 60,
      'dailyGoalMinutes': 528,
      'workDayRule': WorkDayRule.defaults().toJson(),
    });

    expect(parsed.cycleStartDay, 1);
  });

  test('BackupSettings serializes cycleStartDay', () {
    const settings = BackupSettings(
      userName: 'Teste',
      defaultEntryHour: 7,
      defaultEntryMinute: 0,
      defaultExitHour: 16,
      defaultExitMinute: 48,
      lunchBreakMinutes: 60,
      dailyGoalMinutes: 528,
      cycleStartDay: 16,
      workDayRule: WorkDayRule(
        defaultShiftType: ShiftType.firstCommercial,
        customShift: WorkDayRule.defaultFirstCommercialShift,
        saturdayCompensationEnabled: false,
        saturdayCompensationShift: WorkDayRule.defaultSaturdayCompensationShift,
        useBrazilNationalHolidays: false,
        useManausAmazonasHolidays: false,
        holidays: <Holiday>[],
        companyCalendarRules: <CompanyCalendarRule>[],
      ),
    );

    final json = settings.toJson();
    expect(json['cycleStartDay'], 16);
  });
}
