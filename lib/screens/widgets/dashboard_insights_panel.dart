import 'dart:async';

import 'package:auratime/domain/work_schedule/daily_status_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
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
    final engine = WorkScheduleEngine(settings.workDayRule);
    final progress = _todayProgress(settings);
    final workedToday = _workedDurationToday(settings);
    final statusResult = DailyStatusEngine(
      workScheduleEngine: engine,
    ).evaluate(now: _now, todayRecord: widget.todayRecord);
    final statusColor = _statusColor(theme, statusResult.severity);
    final predictedExit = _predictedExit(settings);
    final expectedDuration = engine.calculateExpectedDuration(widget.todayRecord.date);
    final shift = engine.getShiftForDate(widget.todayRecord.date);
    final shiftLabel = engine.getDisplayDayLabel(widget.todayRecord.date);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Column(
        key: ValueKey(
          '${statusResult.statusType.name}_${widget.todayRecord.entryTime}_${widget.todayRecord.exitTime}',
        ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      _statusIcon(statusResult.statusType),
                      color: statusColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statusResult.message,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        fontSize: 16,
                        height: 1.24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildMetaChip(
                    theme: theme,
                    icon: Icons.badge_outlined,
                    label: shiftLabel,
                  ),
                  if (shift != null)
                    _buildMetaChip(
                      theme: theme,
                      icon: Icons.schedule_rounded,
                      label:
                          '${_formatHour(shift.startHour, shift.startMinute)} → ${_formatHour(shift.endHour, shift.endMinute)}',
                    ),
                  if (predictedExit != null)
                    _buildMetaChip(
                      theme: theme,
                      icon: Icons.flag_circle_rounded,
                      label: 'Saída prevista: ${_timeFormatter.format(predictedExit)}',
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progresso da jornada',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% • ${_formatDuration(workedToday)} de ${_formatDuration(expectedDuration)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (predictedExit != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Previsão de saída: ${_timeFormatter.format(predictedExit)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
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
                Text(
                  'Resumo semanal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Saldo: ${_formatSignedDuration(widget.weekBalance)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dias trabalhados: ${widget.weekWorkedDays} • Horas: ${_formatDuration(widget.weekWorkedHours)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  Color _statusColor(ThemeData theme, DailyStatusSeverity severity) {
    switch (severity) {
      case DailyStatusSeverity.success:
        return const Color(0xFF56F09B);
      case DailyStatusSeverity.info:
        return theme.colorScheme.secondary;
      case DailyStatusSeverity.warning:
        return const Color(0xFFFFD166);
      case DailyStatusSeverity.danger:
        return const Color(0xFFFF8A80);
      case DailyStatusSeverity.neutral:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _statusIcon(DailyStatusType type) {
    switch (type) {
      case DailyStatusType.offDay:
        return Icons.weekend_rounded;
      case DailyStatusType.beforeStart:
        return Icons.hourglass_bottom_rounded;
      case DailyStatusType.working:
        return Icons.timelapse_rounded;
      case DailyStatusType.late:
        return Icons.warning_amber_rounded;
      case DailyStatusType.completed:
        return Icons.check_circle_outline_rounded;
      case DailyStatusType.overtime:
        return Icons.bolt_rounded;
      case DailyStatusType.negativeBalance:
        return Icons.trending_down_rounded;
    }
  }

  Widget _buildMetaChip({
    required ThemeData theme,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
    final engine = WorkScheduleEngine(settings.workDayRule);
    if (!engine.isWorkingDay(record.date)) {
      return 0;
    }
    final worked = _workedDurationToday(settings).inMinutes;
    final goal = engine.calculateExpectedDuration(record.date).inMinutes;
    if (goal <= 0) {
      return 0;
    }
    final ratio = worked / goal;
    return ratio.clamp(0, 1).toDouble();
  }

  DateTime? _predictedExit(AppSettings settings) {
    final record = widget.todayRecord;
    if (record.entryTime == null || record.exitTime != null) {
      return null;
    }
    final engine = WorkScheduleEngine(settings.workDayRule);
    if (!engine.isWorkingDay(record.date)) {
      return null;
    }
    return engine.calculateExpectedExit(record.date, record.entryTime!);
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatHour(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatSignedDuration(Duration duration) {
    final sign = duration.inMinutes >= 0 ? '+' : '-';
    return '$sign ${_formatDuration(duration)}';
  }
}
