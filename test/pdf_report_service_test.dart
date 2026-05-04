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

  test('Explicit company rule renders same app label', () {
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
    expect(label, 'Troca');
  });

  test('Saturday compensation rule renders Sábado compensado', () {
    final date = DateTime(2026, 5, 2);
    final rule = WorkDayRule.defaults().copyWith(
      companyCalendarRules: [
        CompanyCalendarRule(
          date: date,
          dayType: WorkDayType.saturdayCompensation,
          note: 'Compensação oficial',
        ),
      ],
    );
    final label = PdfReportService.buildReportDayLabel(date: date, workDayRule: rule);
    expect(label, 'Sábado compensado');
  });

  test('Explicit compensatory day off renders Folga compensatória', () {
    final date = DateTime(2026, 5, 9);
    final rule = WorkDayRule.defaults().copyWith(
      companyCalendarRules: [
        CompanyCalendarRule(
          date: date,
          dayType: WorkDayType.compensatoryDayOff,
          note: 'Folga definida',
        ),
      ],
    );
    final label = PdfReportService.buildReportDayLabel(date: date, workDayRule: rule);
    expect(label, 'Folga compensatória');
  });

  test('Holiday label includes holiday name when available', () {
    final date = DateTime(2026, 9, 7);
    final rule = WorkDayRule.defaults().copyWith(useBrazilNationalHolidays: true);
    final label = PdfReportService.buildReportDayLabel(date: date, workDayRule: rule);
    expect(label, 'Feriado (Independência do Brasil)');
  });

  test('Explicit regular override stays aligned with app label', () {
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
    expect(label, 'Normal');
  });
}
