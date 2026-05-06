import 'package:auratime/screens/history_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    Intl.defaultLocale = 'pt_BR';
  });

  test('cycleStartDay 1 uses calendar month', () {
    final range = computeMonthlyCycleRange(DateTime(2026, 5, 4), 1);

    expect(range.start, DateTime(2026, 5, 1));
    expect(range.end.year, 2026);
    expect(range.end.month, 5);
    expect(range.end.day, 31);
  });

  test('cycleStartDay 16 uses previous/current month cycle', () {
    final range = computeMonthlyCycleRange(DateTime(2026, 5, 4), 16);

    expect(range.start, DateTime(2026, 4, 16));
    expect(range.end.year, 2026);
    expect(range.end.month, 5);
    expect(range.end.day, 15);
  });

  test('subtitle shows cycle range', () {
    final subtitle = buildHistoryCycleSubtitle(
      computeMonthlyCycleRange(DateTime(2026, 5, 4), 16),
    );

    expect(subtitle, 'Ciclo atual: 16 de abr. - 15 de mai.');
  });

  test('multi-month hint shows month names', () {
    final hint = buildHistoryMultiMonthHint(
      computeMonthlyCycleRange(DateTime(2026, 5, 4), 16),
    );

    expect(hint, 'Inclui dias de abril e maio.');
  });

  test('date labels include month abbreviation for multi-month period', () {
    final label = formatHistoryCardDateLabel(
      DateTime(2026, 4, 30),
      includeMonthAbbreviation: true,
    );

    expect(label, '30 de abr.');
  });

  test('history row title includes weekday and date compact', () {
    final label = formatHistoryCardDateWithWeekday(
      DateTime(2026, 5, 4),
      includeMonthAbbreviation: true,
    );

    expect(label, 'Seg • 4 de mai.');
  });

  test('initial month display limits to five records', () {
    final visibleCount = computeVisibleRecordCount(
      totalRecords: 12,
      isCurrentMonthFilter: true,
      showFullCurrentCycle: false,
    );

    expect(visibleCount, 5);
  });

  test('show-all state displays full cycle', () {
    final visibleCount = computeVisibleRecordCount(
      totalRecords: 12,
      isCurrentMonthFilter: true,
      showFullCurrentCycle: true,
    );

    expect(visibleCount, 12);
  });
}
