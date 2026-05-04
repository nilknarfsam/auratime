import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  static final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final DateFormat _timeFormatter = DateFormat('HH:mm', 'pt_BR');
  static final DateFormat _reportDateFormatter = DateFormat(
    "dd/MM/yyyy 'às' HH:mm",
    'pt_BR',
  );

  static Future<void> generateAndPrintReport(
    List<TimeRecord> records,
    Duration totalBalance,
    String periodLabel,
    String periodFileLabel,
    String userName,
  ) async {
    final pdf = pw.Document();
    final generatedAt = DateTime.now();
    final safeUserName = userName.trim().isEmpty ? 'Usuario' : userName.trim();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _buildHeader(generatedAt, periodLabel, safeUserName),
          pw.SizedBox(height: 16),
          _buildTable(records),
          pw.SizedBox(height: 16),
          _buildFooter(totalBalance),
        ],
      ),
    );

    final pdfBytes = await pdf.save();
    final fileName = _buildPdfFileName(
      userName: safeUserName,
      periodLabel: periodFileLabel,
    );
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }

  static pw.Widget _buildHeader(
    DateTime generatedAt,
    String periodLabel,
    String userName,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EFEAFF'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AuraTime - Relatório de Ponto',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3D2E8C'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Usuário: $userName'),
          pw.Text('Período: $periodLabel'),
          pw.Text('Gerado em: ${_reportDateFormatter.format(generatedAt)}'),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(List<TimeRecord> records) {
    final headers = ['Data', 'Entrada', 'Saída', 'Status', 'Saldo do Dia'];
    final workDayRule = AppSettingsService.current.workDayRule;
    final engine = WorkScheduleEngine(workDayRule);
    final data = records.map((record) {
      final status = buildReportDayLabel(
        date: record.date,
        workDayRule: workDayRule,
      );
      final statusWithNote = record.hasNote
          ? '$status\nObs: ${record.note!.trim()}'
          : status;

      final dayType = engine.getDayType(record.date);
      final dayBalance = dayType == WorkDayType.holiday
          ? Duration.zero
          : record.balance;

      return [
        _dateFormatter.format(record.date),
        record.entryTime != null
            ? _timeFormatter.format(record.entryTime!)
            : '--:--',
        record.exitTime != null
            ? _timeFormatter.format(record.exitTime!)
            : '--:--',
        statusWithNote,
        _formatSignedDuration(dayBalance),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor(0.24, 0.18, 0.55),
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      border: pw.TableBorder.all(color: PdfColors.grey300),
    );
  }

  static String buildReportDayLabel({
    required DateTime date,
    required WorkDayRule workDayRule,
  }) {
    final engine = WorkScheduleEngine(workDayRule);
    final dayType = engine.getDayType(date);
    final hasExplicitRule = engine.hasExplicitRuleForDate(date);
    final holiday = engine.getHolidayForDate(date);

    final label = switch (dayType) {
      WorkDayType.regular => hasExplicitRule ? 'Dia normal por exceção' : 'Normal',
      WorkDayType.saturdayCompensation => 'Sábado trabalhado',
      WorkDayType.holiday => 'Feriado',
      WorkDayType.holidayWorkedSwap => 'Feriado trabalhado por troca',
      WorkDayType.compensatoryDayOff => hasExplicitRule
          ? 'Folga compensatória'
          : 'Folga',
    };

    if (dayType == WorkDayType.holiday && holiday != null && holiday.name.trim().isNotEmpty) {
      return '$label (${holiday.name.trim()})';
    }
    return label;
  }

  static pw.Widget _buildFooter(Duration totalBalance) {
    final isPositive = totalBalance.inMinutes >= 0;
    final color = isPositive
        ? PdfColor.fromHex('#2E7D32')
        : PdfColor.fromHex('#B71C1C');

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F6F6FB'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColor.fromHex('#D6D8EA')),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Saldo do período',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.Text(
            '${_formatSignedDuration(totalBalance)} hrs',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatSignedDuration(Duration duration) {
    final sign = duration.inMinutes >= 0 ? '+' : '-';
    final totalMinutes = duration.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$sign $hours:$minutes';
  }

  static String _buildPdfFileName({
    required String userName,
    required String periodLabel,
  }) {
    final rawName = 'AuraTime_${userName}_$periodLabel.pdf';
    return _sanitizeFileName(rawName);
  }

  static String _sanitizeFileName(String input) {
    final withoutAccents = input
        .replaceAll('Ñ', 'N')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[ÁÀÂÃÄ]'), 'A')
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[ÉÈÊË]'), 'E')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[ÍÌÎÏ]'), 'I')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[ÓÒÔÕÖ]'), 'O')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[ÚÙÛÜ]'), 'U')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[Ç]'), 'C')
        .replaceAll(RegExp(r'[ç]'), 'c');

    final normalizedSpaces = withoutAccents.replaceAll(RegExp(r'\s+'), '_');
    final cleaned = normalizedSpaces.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '');
    final condensed = cleaned
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'-+'), '-');
    final trimmed = condensed.replaceAll(RegExp(r'^[_\-.]+|[_\-.]+$'), '');
    if (trimmed.isEmpty || trimmed == '.pdf') {
      return 'AuraTime_Relatorio.pdf';
    }
    return trimmed;
  }
}
