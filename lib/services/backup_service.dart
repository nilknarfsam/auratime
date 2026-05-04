import 'dart:convert';
import 'dart:io';

import 'package:auratime/models/backup_payload.dart';
import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:auratime/services/time_record_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  static const int _backupVersion = 2;
  static const String _appName = 'AuraTime';
  static final DateFormat _fileDateFormat = DateFormat('yyyy-MM-dd_HH-mm');
  static final TimeRecordService _timeRecordService = TimeRecordService();

  static Future<void> exportBackup() async {
    final payload = await _buildBackupPayload();
    final jsonText = const JsonEncoder.withIndent(
      '  ',
    ).convert(payload.toJson());
    final tempDir = await getTemporaryDirectory();
    final backupName = _sanitizeFileName(
      'AuraTime_Backup_${_safeUserName()}_${_fileDateFormat.format(DateTime.now())}.json',
    );
    final backupFile = File('${tempDir.path}/$backupName');
    await backupFile.writeAsString(jsonText, flush: true);
    await Share.shareXFiles([
      XFile(backupFile.path),
    ], text: 'Backup do AuraTime');
  }

  static Future<void> importBackupFromFile() async {
    final selection = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (selection == null || selection.files.isEmpty) {
      return;
    }
    final pickedFile = selection.files.single;
    String? rawJson;
    if (pickedFile.bytes != null) {
      rawJson = utf8.decode(pickedFile.bytes!);
    } else if (pickedFile.path != null) {
      rawJson = await File(pickedFile.path!).readAsString();
    }
    if (rawJson == null || rawJson.trim().isEmpty) {
      throw const FormatException('Arquivo de backup vazio ou inválido.');
    }
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Estrutura de backup inválida.');
    }
    final payload = BackupPayload.fromJson(decoded);
    _validatePayload(payload);
    await _restoreBackupPayload(payload);
  }

  static Future<BackupPayload> _buildBackupPayload() async {
    final settings = AppSettingsService.current;
    final records = await _timeRecordService.getAllRecords();
    final packageInfo = await PackageInfo.fromPlatform();

    return BackupPayload(
      backupVersion: _backupVersion,
      appName: _appName,
      createdAt: DateTime.now().toIso8601String(),
      appVersion: packageInfo.version,
      settings: BackupSettings(
        userName: settings.userName,
        defaultEntryHour: settings.defaultEntryHour,
        defaultEntryMinute: settings.defaultEntryMinute,
        defaultExitHour: settings.defaultExitHour,
        defaultExitMinute: settings.defaultExitMinute,
        lunchBreakMinutes: settings.lunchBreakMinutes,
        dailyGoalMinutes: settings.dailyGoalMinutes,
        workDayRule: settings.workDayRule,
      ),
      records: records
          .map(
            (record) => BackupRecord(
              date: record.date.toIso8601String(),
              entryTime: record.entryTime?.toIso8601String(),
              exitTime: record.exitTime?.toIso8601String(),
              dayType: record.dayType.name,
              note: record.note,
            ),
          )
          .toList(),
    );
  }

  static Future<void> _restoreBackupPayload(BackupPayload payload) async {
    final importedSettings = AppSettings(
      userName: payload.settings.userName.trim().isEmpty
          ? 'Usuário'
          : payload.settings.userName.trim(),
      defaultEntryHour: payload.settings.defaultEntryHour,
      defaultEntryMinute: payload.settings.defaultEntryMinute,
      defaultExitHour: payload.settings.defaultExitHour,
      defaultExitMinute: payload.settings.defaultExitMinute,
      lunchBreakMinutes: payload.settings.lunchBreakMinutes,
      dailyGoalMinutes: payload.settings.dailyGoalMinutes,
      workDayRule: payload.settings.workDayRule,
    );
    await AppSettingsService.save(importedSettings);

    for (final item in payload.records) {
      final parsedDate = DateTime.tryParse(item.date);
      if (parsedDate == null) {
        continue;
      }
      final record = TimeRecord.forDate(
        DateTime(parsedDate.year, parsedDate.month, parsedDate.day),
        entryTime: item.entryTime != null
            ? DateTime.tryParse(item.entryTime!)
            : null,
        exitTime: item.exitTime != null
            ? DateTime.tryParse(item.exitTime!)
            : null,
      );
      record.dayType = _parseDayType(item.dayType);
      record.note = item.note;
      await _timeRecordService.upsertRecordByDate(record);
    }
  }

  static void _validatePayload(BackupPayload payload) {
    final appName = payload.appName.trim().toLowerCase();
    if (appName != 'auratime') {
      throw const FormatException(
        'Este arquivo não parece ser um backup do AuraTime.',
      );
    }
    if (payload.records.isEmpty) {
      throw const FormatException('Backup sem registros para importar.');
    }
    if (payload.settings.userName.isEmpty &&
        payload.settings.defaultEntryHour == 0 &&
        payload.settings.defaultExitHour == 0) {
      throw const FormatException('Backup sem configurações válidas.');
    }
  }

  static DayType _parseDayType(String value) {
    return DayType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => DayType.regular,
    );
  }

  static String _safeUserName() {
    final name = AppSettingsService.current.userName.trim();
    return name.isEmpty ? 'Usuario' : name;
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
    if (trimmed.isEmpty) {
      return 'AuraTime_Backup.json';
    }
    return trimmed;
  }
}
