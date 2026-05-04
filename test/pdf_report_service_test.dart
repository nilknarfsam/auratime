import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/services/pdf_report_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Weekend without explicit rule renders Folga', () {
    final rule = WorkDayRule.defaults();
    final saturdayLabel = PdfReportService.buildReportDayLabel(
      date: DateTime(2026, 5, 2),
      workDayRule: rule,
    );
    final sundayLabel = PdfReportService.buildReportDayLabel(
      date: DateTime(2026, 5, 3),
      workDayRule: rule,
    );

    expect(saturdayLabel, 'Folga');
    expect(sundayLabel, 'Folga');
  });

  test('Explicit company rule renders factory-friendly label', () {
    final date = DateTime(2026, 5, 10);
    final rule = WorkDayRule.defaults().copyWith(
      companyCalendarRules: [
        CompanyCalendarRule(
          date: date,
          dayType: WorkDayType.holidayWorkedSwap,
          note: 'Troca definida pela empresa',
        ),
      ],
    );
    final label = PdfReportService.buildReportDayLabel(date: date, workDayRule: rule);
    expect(label, 'Feriado trabalhado por troca');
  });

  test('Holiday label includes holiday name when available', () {
    final date = DateTime(2026, 9, 7);
    final rule = WorkDayRule.defaults().copyWith(useBrazilNationalHolidays: true);
    final label = PdfReportService.buildReportDayLabel(date: date, workDayRule: rule);
    expect(label, 'Feriado (Independência do Brasil)');
  });

  test('Explicit regular override renders Dia normal por exceção', () {
    final date = DateTime(2026, 9, 7);
    final rule = WorkDayRule.defaults().copyWith(
      useBrazilNationalHolidays: true,
      companyCalendarRules: [
        CompanyCalendarRule(
          date: date,
          dayType: WorkDayType.regular,
          note: 'Operação especial',
        ),
      ],
    );
    final label = PdfReportService.buildReportDayLabel(date: date, workDayRule: rule);
    expect(label, 'Dia normal por exceção');
  });
}
