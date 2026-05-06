import 'dart:async';

import 'package:auratime/core/ui/snackbar_helper.dart';
import 'package:auratime/domain/insights/insights_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/models/time_record.dart';
import 'package:auratime/screens/widgets/dashboard_header.dart';
import 'package:auratime/screens/widgets/dashboard_insights_panel.dart';
import 'package:auratime/screens/widgets/punch_button.dart';
import 'package:auratime/screens/widgets/time_record_card.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:auratime/services/time_record_service.dart';
import 'package:auratime/services/widget_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _RecordField { entry, exit }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onHistoryRefreshRequested});

  final VoidCallback onHistoryRefreshRequested;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TimeRecordService _timeRecordService = TimeRecordService();
  TimeRecord _todayRecord = TimeRecord();
  Duration _weekBalance = Duration.zero;
  Duration _weekWorkedHours = Duration.zero;
  int _weekWorkedDays = 0;
  List<InsightItem> _insights = const [];
  final ValueNotifier<int> _todayRevision = ValueNotifier<int>(0);
  final ValueNotifier<int> _weekRevision = ValueNotifier<int>(0);
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier<bool>(false);
  bool _todayLoadFailed = false;
  late final DateFormat _hourFormatter;
  late final Listenable _punchAreaListenable;

  @override
  void initState() {
    super.initState();
    _hourFormatter = DateFormat('HH:mm');
    _punchAreaListenable = Listenable.merge([_loadingNotifier, _todayRevision]);
    _loadTodayRecord();
  }

  @override
  void dispose() {
    _todayRevision.dispose();
    _weekRevision.dispose();
    _loadingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppSettingsService.current;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const scrollPadding = EdgeInsets.fromLTRB(20, 16, 20, 20);
            final minScrollContentHeight = constraints.hasBoundedHeight
                ? (constraints.maxHeight - scrollPadding.vertical).clamp(0.0, double.infinity)
                : 0.0;
            return SingleChildScrollView(
              padding: scrollPadding,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minScrollContentHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DashboardHeader(),
                    const SizedBox(height: 14),
                    DashboardInsightsPanel(
                      todayRevision: _todayRevision,
                      weekRevision: _weekRevision,
                      todayRecord: () => _todayRecord,
                      weekWorkedDays: _weekWorkedDays,
                      weekWorkedHours: _weekWorkedHours,
                      weekBalance: _weekBalance,
                      insights: _insights,
                    ),
                    if (_todayLoadFailed) ...[
                      const SizedBox(height: 16),
                      _buildLoadFailedBanner(theme),
                    ],
                    const SizedBox(height: 18),
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _punchAreaListenable,
                        builder: (context, _) {
                          final isLoading = _loadingNotifier.value;
                          final engine = WorkScheduleEngine(settings.workDayRule);
                          final dayType = engine.getDayType(_todayRecord.date);
                          final shift = engine.getShiftForDate(_todayRecord.date);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isLoading)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: theme.colorScheme.outline.withValues(alpha: 0.18),
                                    ),
                                    color: theme.colorScheme.surface.withValues(alpha: 0.18),
                                  ),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 10),
                                      Text('Carregando…'),
                                    ],
                                  ),
                                )
                              else
                                PunchButton(
                                  canPunch: _isCalendarTodayRecord &&
                                      _isWorkingDay(dayType) &&
                                      !_isDayFinalized,
                                  isDayFinalized: _isDayFinalized,
                                  onPressed: _isCalendarTodayRecord &&
                                          _isWorkingDay(dayType) &&
                                          !_isDayFinalized
                                      ? _recordNow
                                      : null,
                                ),
                              const SizedBox(height: 20),
                              if (_isWorkingDay(dayType)) ...[
                                TimeRecordCard(
                                  label: 'Entrada',
                                  value: _todayRecord.entryTime,
                                  expected: _formatExpectedTime(
                                    shift?.startHour ?? settings.defaultEntryHour,
                                    shift?.startMinute ?? settings.defaultEntryMinute,
                                  ),
                                  timeFormatter: _hourFormatter,
                                  onTap: isLoading || !_isCalendarTodayRecord
                                      ? null
                                      : () => _editRecordTime(
                                            _RecordField.entry,
                                            _todayRecord.entryTime,
                                          ),
                                ),
                                const SizedBox(height: 12),
                                TimeRecordCard(
                                  label: 'Saída',
                                  value: _todayRecord.exitTime,
                                  expected: _formatExpectedTime(
                                    shift?.endHour ?? settings.defaultExitHour,
                                    shift?.endMinute ?? settings.defaultExitMinute,
                                  ),
                                  timeFormatter: _hourFormatter,
                                  onTap: isLoading || !_isCalendarTodayRecord
                                      ? null
                                      : () => _editRecordTime(
                                            _RecordField.exit,
                                            _todayRecord.exitTime,
                                          ),
                                ),
                                const SizedBox(height: 14),
                                _buildNoteSection(theme, isLoading),
                              ] else
                                _buildSpecialDayMessage(theme, dayType),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isWorkingDay(WorkDayType dayType) {
    return dayType == WorkDayType.regular ||
        dayType == WorkDayType.saturdayCompensation ||
        dayType == WorkDayType.holidayWorkedSwap;
  }

  Widget _buildLoadFailedBanner(ThemeData theme) {
    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nenhum dado carregado',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Não foi possível carregar o registro de hoje.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loadTodayRecord,
                child: const Text('Tentar novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialDayMessage(ThemeData theme, WorkDayType dayType) {
    final engine = WorkScheduleEngine(AppSettingsService.current.workDayRule);
    final message = switch (dayType) {
      WorkDayType.holiday => 'Aproveite seu feriado!',
      WorkDayType.compensatoryDayOff => engine.hasExplicitRuleForDate(_todayRecord.date)
          ? 'Aproveite sua folga compensatória!'
          : 'Aproveite sua folga!',
      _ => 'Dia sem jornada prevista.',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildNoteSection(ThemeData theme, bool isLoading) {
    return TextButton.icon(
      onPressed: isLoading || !_isCalendarTodayRecord ? null : _showNoteDialog,
      icon: const Icon(Icons.edit_note_rounded),
      label: Text(_todayRecord.hasNote ? 'Editar observação' : 'Adicionar observação'),
    );
  }

  Future<void> _loadTodayRecord() async {
    if (mounted) {
      setState(() => _todayLoadFailed = false);
    }
    _loadingNotifier.value = true;
    try {
      final record = await _timeRecordService.getTodayRecord();
      if (!mounted) {
        return;
      }
      setState(() {
        _todayRecord = record;
        _todayLoadFailed = false;
      });
      _loadingNotifier.value = false;
      _todayRevision.value++;
      unawaited(_refreshWeekSummary());
      unawaited(syncHomeWidgetStatus());
    } catch (_) {
      if (mounted) {
        setState(() => _todayLoadFailed = true);
        _loadingNotifier.value = false;
      }
    }
  }

  Future<void> _recordNow() async {
    _loadingNotifier.value = true;
    try {
      final result = await _timeRecordService.recordCurrentTime();
      if (!mounted) {
        return;
      }
      _todayRecord = result.record;
      _todayRevision.value++;
      await _refreshWeekSummary();
      if (!mounted) {
        return;
      }
      unawaited(syncHomeWidgetStatus());
      widget.onHistoryRefreshRequested();
      SnackBarHelper.showSuccess(context, 'Ponto registrado com sucesso!');
    } catch (_) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Não foi possível registrar o ponto.');
      }
    } finally {
      if (mounted) {
        _loadingNotifier.value = false;
      }
    }
  }

  Future<void> _editRecordTime(_RecordField field, DateTime? currentValue) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentValue != null
          ? TimeOfDay(hour: currentValue.hour, minute: currentValue.minute)
          : TimeOfDay.now(),
    );
    if (selectedTime == null) {
      return;
    }
    final today = DateTime.now();
    final selectedDateTime = DateTime(
      today.year,
      today.month,
      today.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    if (field == _RecordField.entry) {
      _todayRecord.entryTime = selectedDateTime;
    } else {
      _todayRecord.exitTime = selectedDateTime;
    }
    await _timeRecordService.saveRecord(_todayRecord);
    if (mounted) {
      _todayRevision.value++;
      unawaited(_refreshWeekSummary());
      widget.onHistoryRefreshRequested();
    }
  }

  Future<void> _showNoteDialog() async {
    final controller = TextEditingController(text: _todayRecord.note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observação do dia'),
        content: TextField(controller: controller, maxLength: 150),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) {
      return;
    }
    _todayRecord.note = result.isEmpty ? null : result;
    await _timeRecordService.saveRecord(_todayRecord);
    if (mounted) {
      _todayRevision.value++;
      unawaited(_refreshWeekSummary());
      widget.onHistoryRefreshRequested();
    }
  }

  String _formatExpectedTime(int hour, int minute) {
    return _hourFormatter.format(DateTime(2000, 1, 1, hour, minute));
  }

  bool get _isDayFinalized => _todayRecord.entryTime != null && _todayRecord.exitTime != null;

  bool get _isCalendarTodayRecord {
    final d = _todayRecord.date;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  Future<void> _refreshWeekSummary() async {
    try {
      final summary = await _loadWeekSummary();
      if (!mounted) {
        return;
      }
      _weekBalance = summary.balance;
      _weekWorkedHours = summary.workedHours;
      _weekWorkedDays = summary.workedDays;
      _insights = summary.insights;
      _weekRevision.value++;
    } catch (_) {
      // Keep the current values if summary refresh fails.
    }
  }

  Future<_WeeklySummary> _loadWeekSummary() async {
    final records = await _timeRecordService.getAllRecords();
    final now = DateTime.now();
    final currentDay = DateTime(now.year, now.month, now.day);
    final weekStart = currentDay.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    Duration balance = Duration.zero;
    Duration workedHours = Duration.zero;
    int workedDays = 0;
    for (final record in records) {
      final day = DateTime(record.date.year, record.date.month, record.date.day);
      if (day.isBefore(weekStart) || day.isAfter(weekEnd)) {
        continue;
      }
      balance += record.balance;
      workedHours += record.totalWorkedHours;
      if (record.totalWorkedHours > Duration.zero) {
        workedDays++;
      }
    }
    final insightsEngine = InsightsEngine(
      workScheduleEngine: WorkScheduleEngine(AppSettingsService.current.workDayRule),
    );
    final insights = insightsEngine.analyze(records: records, now: now);
    return _WeeklySummary(
      balance: balance,
      workedHours: workedHours,
      workedDays: workedDays,
      insights: insights,
    );
  }
}

class _WeeklySummary {
  const _WeeklySummary({
    required this.balance,
    required this.workedHours,
    required this.workedDays,
    this.insights = const [],
  });

  final Duration balance;
  final Duration workedHours;
  final int workedDays;
  final List<InsightItem> insights;
}
