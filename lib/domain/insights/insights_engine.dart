import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/models/time_record.dart';

enum InsightSeverity { info, warning, success }

class InsightItem {
  const InsightItem({
    required this.message,
    required this.severity,
  });

  final String message;
  final InsightSeverity severity;
}

class InsightsEngine {
  const InsightsEngine({required this.workScheduleEngine});

  final WorkScheduleEngine workScheduleEngine;

  List<InsightItem> analyze({
    required List<TimeRecord> records,
    required DateTime now,
    int maxItems = 3,
  }) {
    if (records.isEmpty) {
      return const [
        InsightItem(
          message: 'Sem dados suficientes para gerar insights ainda.',
          severity: InsightSeverity.info,
        ),
      ];
    }

    final normalizedNow = DateTime(now.year, now.month, now.day);
    final last7Start = normalizedNow.subtract(const Duration(days: 6));
    final last30Start = normalizedNow.subtract(const Duration(days: 29));

    final last7 = records.where((r) => !_day(r.date).isBefore(last7Start)).toList();
    final last30 = records.where((r) => !_day(r.date).isBefore(last30Start)).toList();

    final insights = <InsightItem>[];
    final lateInsight = _latePatternInsight(last30);
    if (lateInsight != null) {
      insights.add(lateInsight);
    }
    final overtimeInsight = _overtimeInsight(last30);
    if (overtimeInsight != null) {
      insights.add(overtimeInsight);
    }
    final avgBalanceInsight = _averageBalanceInsight(last7);
    if (avgBalanceInsight != null) {
      insights.add(avgBalanceInsight);
    }
    final trendInsight = _trendInsight(last30);
    if (trendInsight != null) {
      insights.add(trendInsight);
    }
    final recoveryInsight = _recoveryInsight(last30);
    if (recoveryInsight != null) {
      insights.add(recoveryInsight);
    }

    if (insights.isEmpty) {
      return const [
        InsightItem(
          message: 'Seu histórico está estável nos últimos dias.',
          severity: InsightSeverity.info,
        ),
      ];
    }
    return insights.take(maxItems).toList();
  }

  InsightItem? _latePatternInsight(List<TimeRecord> records) {
    int workingDays = 0;
    int lateDays = 0;
    for (final record in records) {
      if (record.entryTime == null) {
        continue;
      }
      final shift = workScheduleEngine.getShiftForDate(record.date);
      if (shift == null) {
        continue;
      }
      workingDays++;
      final expectedStart = DateTime(
        record.date.year,
        record.date.month,
        record.date.day,
        shift.startHour,
        shift.startMinute,
      );
      if (record.entryTime!.isAfter(expectedStart)) {
        lateDays++;
      }
    }
    if (workingDays < 4 || lateDays < 3) {
      return null;
    }
    return InsightItem(
      message: 'Você teve $lateDays entradas com atraso nos últimos dias.',
      severity: InsightSeverity.warning,
    );
  }

  InsightItem? _overtimeInsight(List<TimeRecord> records) {
    int overtimeDays = 0;
    for (final record in records) {
      if (record.balance.inMinutes > 0) {
        overtimeDays++;
      }
    }
    if (overtimeDays < 3) {
      return null;
    }
    return InsightItem(
      message: 'Padrão de hora extra em $overtimeDays dias recentes.',
      severity: InsightSeverity.success,
    );
  }

  InsightItem? _averageBalanceInsight(List<TimeRecord> records) {
    if (records.isEmpty) {
      return null;
    }
    Duration total = Duration.zero;
    for (final record in records) {
      total += record.balance;
    }
    final avgMinutes = total.inMinutes ~/ records.length;
    final avg = Duration(minutes: avgMinutes);
    final sign = avg.inMinutes >= 0 ? '+' : '-';
    final text = _formatDuration(avg.abs());
    return InsightItem(
      message: 'Saldo médio diário (7 dias): $sign$text',
      severity: avg.inMinutes >= 0 ? InsightSeverity.success : InsightSeverity.warning,
    );
  }

  InsightItem? _trendInsight(List<TimeRecord> records) {
    if (records.length < 10) {
      return null;
    }
    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
    final midpoint = sorted.length ~/ 2;
    final firstHalf = sorted.take(midpoint);
    final secondHalf = sorted.skip(midpoint);

    int firstSum = 0;
    int secondSum = 0;
    for (final r in firstHalf) {
      firstSum += r.balance.inMinutes;
    }
    for (final r in secondHalf) {
      secondSum += r.balance.inMinutes;
    }
    if (secondSum > firstSum + 30) {
      return const InsightItem(
        message: 'Tendência semanal positiva no saldo de horas.',
        severity: InsightSeverity.success,
      );
    }
    if (secondSum + 30 < firstSum) {
      return const InsightItem(
        message: 'Tendência de queda no saldo semanal recente.',
        severity: InsightSeverity.warning,
      );
    }
    return null;
  }

  InsightItem? _recoveryInsight(List<TimeRecord> records) {
    if (records.length < 4) {
      return null;
    }
    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
    final last4 = sorted.skip(sorted.length - 4).toList();
    final first2 = last4.take(2);
    final last2 = last4.skip(2);
    int early = 0;
    int recent = 0;
    for (final r in first2) {
      early += r.balance.inMinutes;
    }
    for (final r in last2) {
      recent += r.balance.inMinutes;
    }
    if (early < 0 && recent > 0) {
      return const InsightItem(
        message: 'Boa recuperação recente: saldo saiu de negativo para positivo.',
        severity: InsightSeverity.success,
      );
    }
    return null;
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }
}
