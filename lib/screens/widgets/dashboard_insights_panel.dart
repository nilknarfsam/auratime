import 'dart:async';

import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardInsightsPanel extends StatefulWidget {
  const DashboardInsightsPanel({
    super.key,
    required this.todayRecord,
    required this.weekWorkedDays,
    required this.weekWorkedHours,
    required this.weekBalance,
  });

  final TimeRecord todayRecord;
  final int weekWorkedDays;
  final Duration weekWorkedHours;
  final Duration weekBalance;

  @override
  State<DashboardInsightsPanel> createState() => _DashboardInsightsPanelState();
}

class _DashboardInsightsPanelState extends State<DashboardInsightsPanel> {
  late DateTime _now;
  Timer? _refreshTimer;
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppSettingsService.current;
    final progress = _todayProgress(settings);
    final workedToday = _workedDurationToday(settings);
    final status = _statusText();
    final statusColor = _statusColor(theme);
    final predictedExit = _predictedExit(settings);

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.track_changes_rounded, color: statusColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Status do dia: $status',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progresso da jornada', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% • ${_formatDuration(workedToday)} de ${_formatDuration(settings.dailyGoalDuration)}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (predictedExit != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Previsão de saída: ${_timeFormatter.format(predictedExit)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resumo semanal', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Saldo: ${_formatSignedDuration(widget.weekBalance)}',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dias trabalhados: ${widget.weekWorkedDays} • Horas: ${_formatDuration(widget.weekWorkedHours)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _statusText() {
    final record = widget.todayRecord;
    if (record.dayType == DayType.holiday) {
      return 'Feriado';
    }
    if (record.dayType == DayType.dayOff) {
      return 'Folga';
    }
    if (record.entryTime == null) {
      return 'Aguardando entrada';
    }
    if (record.exitTime == null) {
      return 'Expediente em andamento';
    }
    return 'Dia finalizado';
  }

  Color _statusColor(ThemeData theme) {
    final status = _statusText();
    if (status == 'Dia finalizado') {
      return const Color(0xFF56F09B);
    }
    if (status == 'Expediente em andamento') {
      return theme.colorScheme.secondary;
    }
    if (status == 'Aguardando entrada') {
      return const Color(0xFFFFD166);
    }
    return theme.colorScheme.onSurfaceVariant;
  }

  Duration _workedDurationToday(AppSettings settings) {
    final record = widget.todayRecord;
    if (record.entryTime == null) {
      return Duration.zero;
    }
    if (record.exitTime != null) {
      return record.totalWorkedHours;
    }
    final gross = _now.difference(record.entryTime!);
    if (gross <= Duration.zero) {
      return Duration.zero;
    }
    if (gross <= settings.lunchBreakDuration) {
      return gross;
    }
    return gross - settings.lunchBreakDuration;
  }

  double _todayProgress(AppSettings settings) {
    final record = widget.todayRecord;
    if (record.dayType == DayType.holiday || record.dayType == DayType.dayOff) {
      return 0;
    }
    final worked = _workedDurationToday(settings).inMinutes;
    final goal = settings.dailyGoalDuration.inMinutes;
    if (goal <= 0) {
      return 0;
    }
    final ratio = worked / goal;
    return ratio.clamp(0, 1).toDouble();
  }

  DateTime? _predictedExit(AppSettings settings) {
    final record = widget.todayRecord;
    if (record.dayType != DayType.regular ||
        record.entryTime == null ||
        record.exitTime != null) {
      return null;
    }
    return record.entryTime!.add(
      settings.dailyGoalDuration + settings.lunchBreakDuration,
    );
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatSignedDuration(Duration duration) {
    final sign = duration.inMinutes >= 0 ? '+' : '-';
    return '$sign ${_formatDuration(duration)}';
  }
}
