import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/models/time_record.dart';

enum DailyStatusType {
  offDay,
  beforeStart,
  working,
  late,
  completed,
  overtime,
  negativeBalance,
}

enum DailyStatusSeverity { neutral, info, warning, success, danger }

class DailyStatusResult {
  const DailyStatusResult({
    required this.statusType,
    required this.message,
    required this.severity,
  });

  final DailyStatusType statusType;
  final String message;
  final DailyStatusSeverity severity;
}

class DailyStatusEngine {
  const DailyStatusEngine({required this.workScheduleEngine});

  final WorkScheduleEngine workScheduleEngine;

  DailyStatusResult evaluate({
    required DateTime now,
    required TimeRecord todayRecord,
  }) {
    final day = DateTime(
      todayRecord.date.year,
      todayRecord.date.month,
      todayRecord.date.day,
    );
    final shift = workScheduleEngine.getShiftForDate(day);
    if (shift == null) {
      return const DailyStatusResult(
        statusType: DailyStatusType.offDay,
        message: 'Hoje é folga',
        severity: DailyStatusSeverity.neutral,
      );
    }

    final scheduledStart = DateTime(
      day.year,
      day.month,
      day.day,
      shift.startHour,
      shift.startMinute,
    );

    if (todayRecord.entryTime == null) {
      if (now.isAfter(scheduledStart)) {
        final delay = now.difference(scheduledStart);
        return DailyStatusResult(
          statusType: DailyStatusType.late,
          message: 'Você está atrasado em ${_formatDuration(delay)}',
          severity: DailyStatusSeverity.warning,
        );
      }
      return const DailyStatusResult(
        statusType: DailyStatusType.beforeStart,
        message: 'Você ainda não iniciou sua jornada',
        severity: DailyStatusSeverity.info,
      );
    }

    final expectedExit = workScheduleEngine.calculateExpectedExit(
      day,
      todayRecord.entryTime!,
    );
    if (expectedExit == null) {
      return const DailyStatusResult(
        statusType: DailyStatusType.working,
        message: 'Você está em jornada',
        severity: DailyStatusSeverity.info,
      );
    }

    if (todayRecord.exitTime == null) {
      final lateCheckIn = todayRecord.entryTime!.isAfter(scheduledStart);
      if (lateCheckIn) {
        final delay = todayRecord.entryTime!.difference(scheduledStart);
        return DailyStatusResult(
          statusType: DailyStatusType.late,
          message: 'Você iniciou com atraso de ${_formatDuration(delay)}',
          severity: DailyStatusSeverity.warning,
        );
      }
      if (now.isBefore(expectedExit)) {
        final remaining = expectedExit.difference(now);
        return DailyStatusResult(
          statusType: DailyStatusType.working,
          message: 'Você está em jornada • faltam ${_formatDuration(remaining)}',
          severity: DailyStatusSeverity.info,
        );
      }
      final overtime = now.difference(expectedExit);
      return DailyStatusResult(
        statusType: DailyStatusType.overtime,
        message: 'Você está em hora extra há ${_formatDuration(overtime)}',
        severity: DailyStatusSeverity.success,
      );
    }

    final worked = todayRecord.totalWorkedHours;
    final expected = workScheduleEngine.calculateExpectedDuration(day);
    final balance = worked - expected;
    if (balance.inMinutes < 0) {
      return DailyStatusResult(
        statusType: DailyStatusType.negativeBalance,
        message: 'Dia concluído com saldo negativo de ${_formatDuration(balance.abs())}',
        severity: DailyStatusSeverity.danger,
      );
    }
    if (balance.inMinutes > 0) {
      return DailyStatusResult(
        statusType: DailyStatusType.overtime,
        message: 'Dia concluído com hora extra de ${_formatDuration(balance)}',
        severity: DailyStatusSeverity.success,
      );
    }
    return const DailyStatusResult(
      statusType: DailyStatusType.completed,
      message: 'Você já cumpriu sua jornada',
      severity: DailyStatusSeverity.success,
    );
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
