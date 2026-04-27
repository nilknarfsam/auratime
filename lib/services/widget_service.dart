import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/time_record_service.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

const String _androidWidgetQualifiedName = 'com.seunome.auratime.AuratimeWidgetProvider';

final DateFormat _widgetTimeFormat = DateFormat('HH:mm');

/// Chamado pelo Android ao tocar em "Bater Ponto" no widget (isolate separado).
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (uri?.host != 'bater_ponto') {
    return;
  }

  await TimeRecordService.initialize();
  final service = TimeRecordService();
  final current = await service.getTodayRecord();

  if (current.dayType != DayType.regular) {
    await HomeWidget.saveWidgetData(
      'widget_status_text',
      _statusTextForRecord(current),
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: _androidWidgetQualifiedName);
    return;
  }

  await service.recordCurrentTime();
  final updated = await service.getTodayRecord();
  await HomeWidget.saveWidgetData(
    'widget_status_text',
    _statusTextForRecord(updated),
  );
  await HomeWidget.updateWidget(qualifiedAndroidName: _androidWidgetQualifiedName);
}

/// Atualiza o texto exibido no widget (ex.: após abrir o app e sincronizar Isar).
Future<void> syncHomeWidgetStatus() async {
  try {
    await TimeRecordService.initialize();
  } catch (_) {
    return;
  }

  final service = TimeRecordService();
  final record = await service.getTodayRecord();
  await HomeWidget.saveWidgetData(
    'widget_status_text',
    _statusTextForRecord(record),
  );
  await HomeWidget.updateWidget(qualifiedAndroidName: _androidWidgetQualifiedName);
}

String _statusTextForRecord(TimeRecord record) {
  if (record.dayType == DayType.holiday) {
    return 'Feriado — use o app para este dia';
  }
  if (record.dayType == DayType.dayOff) {
    return 'Folga — use o app para este dia';
  }

  if (record.entryTime == null && record.exitTime == null) {
    return 'Nenhuma batida hoje';
  }
  if (record.entryTime != null && record.exitTime == null) {
    return 'Entrada ${_widgetTimeFormat.format(record.entryTime!)} · aguardando saída';
  }
  if (record.entryTime != null && record.exitTime != null) {
    return 'Entrada ${_widgetTimeFormat.format(record.entryTime!)} · Saída ${_widgetTimeFormat.format(record.exitTime!)}';
  }
  if (record.exitTime != null) {
    return 'Saída ${_widgetTimeFormat.format(record.exitTime!)}';
  }
  return 'Abra o AuraTime';
}
