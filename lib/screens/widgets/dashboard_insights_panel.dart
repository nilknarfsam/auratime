import 'dart:async';

import 'package:auratime/domain/insights/insights_engine.dart';
import 'package:auratime/domain/work_schedule/daily_status_engine.dart';
import 'package:auratime/domain/work_schedule/work_day_accounting.dart';
import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

bool shouldShowInsightInStatusCard(InsightItem insight) {
  final message = insight.message.toLowerCase();
  return !message.contains('padrão de hora extra');
}

/// Dashboard insights: status/progress tick locally; insights and weekly summary
/// rebuild only when [weekRevision] notifies (localized updates from parent).
class DashboardInsightsPanel extends StatelessWidget {
  const DashboardInsightsPanel({
    super.key,
    required this.todayRevision,
    required this.weekRevision,
    required this.todayRecord,
    required this.weekWorkedDays,
    required this.weekWorkedHours,
    required this.weekBalance,
    required this.insights,
  });

  final ValueNotifier<int> todayRevision;
  final ValueNotifier<int> weekRevision;
  final TimeRecord Function() todayRecord;
  final int weekWorkedDays;
  final Duration weekWorkedHours;
  final Duration weekBalance;
  final List<InsightItem> insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([todayRevision, weekRevision]),
          builder: (context, child) {
            return RepaintBoundary(
              child: _DashboardLiveMetricsBlock(
                key: ValueKey(todayRecord().date),
                todayRecord: todayRecord,
                insights: insights,
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: weekRevision,
          builder: (context, child) {
            return RepaintBoundary(
              child: _WeeklySummaryCard(
                weekBalance: weekBalance,
                weekWorkedDays: weekWorkedDays,
                weekWorkedHours: weekWorkedHours,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Status row, meta chips, and journey progress. Single [Timer] rebuilds this subtree every 30s.
class _DashboardLiveMetricsBlock extends StatefulWidget {
  const _DashboardLiveMetricsBlock({
    super.key,
    required this.todayRecord,
    required this.insights,
  });

  final TimeRecord Function() todayRecord;
  final List<InsightItem> insights;

  @override
  State<_DashboardLiveMetricsBlock> createState() =>
      _DashboardLiveMetricsBlockState();
}

class _DashboardLiveMetricsBlockState
    extends State<_DashboardLiveMetricsBlock> {
  late DateTime _now;
  Timer? _refreshTimer;
  final DateFormat _timeFormatter = DateFormat('HH:mm');
  late WorkScheduleEngine _engine;
  late DailyStatusEngine _statusEngine;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _bindEngines();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) {
        return;
      }
      setState(() => _now = DateTime.now());
    });
    AppSettingsService.settingsListenable.addListener(_onSettingsChanged);
  }

  void _bindEngines() {
    _engine = WorkScheduleEngine(AppSettingsService.current.workDayRule);
    _statusEngine = DailyStatusEngine(workScheduleEngine: _engine);
  }

  void _onSettingsChanged() {
    if (!mounted) {
      return;
    }
    setState(_bindEngines);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    AppSettingsService.settingsListenable.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppSettingsService.current;
    final record = widget.todayRecord();
    final statusResult = _statusEngine.evaluate(now: _now, todayRecord: record);
    final statusColor = _statusColor(theme, statusResult.severity);
    final predictedExit = _predictedExit(settings, record);
    final shift = _engine.getShiftForDate(record.date);
    final shiftLabel = _engine.getDisplayDayLabel(record.date);

    final progress = _todayProgress(settings, record);
    final workedToday = _workedDurationToday(settings, record);
    final expectedGross = _engine.calculateExpectedDuration(record.date);
    final expectedNet = WorkDayAccounting.expectedNetWork(
      grossShiftDuration: expectedGross,
      lunchBreak: settings.lunchBreakDuration,
    );
    final visibleInsights = widget.insights
        .where(shouldShowInsightInStatusCard)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Container(
            key: ValueKey(
              '${statusResult.statusType.name}_${record.entryTime}_${record.exitTime}',
            ),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.28)),
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
                        label:
                            'Saída prevista: ${_timeFormatter.format(predictedExit)}',
                      ),
                  ],
                ),
                if (visibleInsights.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    visibleInsights.first.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
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
                    backgroundColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% • ${_formatDuration(workedToday)} de ${_formatDuration(expectedNet)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Duration _workedDurationToday(AppSettings settings, TimeRecord record) {
    return WorkDayAccounting.workedNetSession(
      entry: record.entryTime,
      exit: record.exitTime,
      now: _now,
      lunchBreak: settings.lunchBreakDuration,
    );
  }

  double _todayProgress(AppSettings settings, TimeRecord record) {
    if (!_engine.isWorkingDay(record.date)) {
      return 0;
    }
    final worked = _workedDurationToday(settings, record);
    final expectedNet = WorkDayAccounting.expectedNetWork(
      grossShiftDuration: _engine.calculateExpectedDuration(record.date),
      lunchBreak: settings.lunchBreakDuration,
    );
    return WorkDayAccounting.progress01(
      workedNet: worked,
      expectedNet: expectedNet,
    );
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  DateTime? _predictedExit(AppSettings settings, TimeRecord record) {
    if (record.entryTime == null || record.exitTime != null) {
      return null;
    }
    if (!_engine.isWorkingDay(record.date)) {
      return null;
    }
    return _engine.calculateExpectedExit(record.date, record.entryTime!);
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

  String _formatHour(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({
    required this.weekBalance,
    required this.weekWorkedDays,
    required this.weekWorkedHours,
  });

  final Duration weekBalance;
  final int weekWorkedDays;
  final Duration weekWorkedHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
              'Saldo: ${_formatSignedDuration(weekBalance)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dias trabalhados: $weekWorkedDays • Horas: ${_formatDuration(weekWorkedHours)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
