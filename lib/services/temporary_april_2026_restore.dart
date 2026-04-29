// TEMPORÁRIO — remover este arquivo e o botão em Configurações após a
// restauração definitiva via backup/importação. Não manter em produção.

import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/time_record_service.dart';

/// Restaura apenas os três dias de abril/2026 listados abaixo; não altera
/// outras datas. Usa [TimeRecordService.upsertRecordByDate] para evitar
/// duplicidade por data (substitui se já existir).
class TemporaryApril2026Restore {
  static const String _note =
      'Restaurado manualmente do relatório PDF Abril/2026';

  static Future<void> restoreLostRecords(
    TimeRecordService timeRecordService,
  ) async {
    await timeRecordService.upsertRecordByDate(
      _record(
        year: 2026,
        month: 4,
        day: 27,
        entryHour: 6,
        entryMinute: 55,
        exitHour: 17,
        exitMinute: 45,
      ),
    );
    await timeRecordService.upsertRecordByDate(
      _record(
        year: 2026,
        month: 4,
        day: 28,
        entryHour: 7,
        entryMinute: 14,
        exitHour: 16,
        exitMinute: 44,
      ),
    );
    await timeRecordService.upsertRecordByDate(
      _record(
        year: 2026,
        month: 4,
        day: 29,
        entryHour: 6,
        entryMinute: 52,
        exitHour: null,
        exitMinute: null,
      ),
    );
  }

  static TimeRecord _record({
    required int year,
    required int month,
    required int day,
    required int entryHour,
    required int entryMinute,
    required int? exitHour,
    required int? exitMinute,
  }) {
    final date = DateTime(year, month, day);
    final record = TimeRecord.forDate(
      date,
      entryTime: DateTime(year, month, day, entryHour, entryMinute),
      exitTime: exitHour != null && exitMinute != null
          ? DateTime(year, month, day, exitHour, exitMinute)
          : null,
    );
    record.dayType = DayType.regular;
    record.note = _note;
    return record;
  }
}
