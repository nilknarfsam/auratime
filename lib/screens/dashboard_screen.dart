import 'dart:async';

import 'package:auratime/core/ui/snackbar_helper.dart';
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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TimeRecordService _timeRecordService = TimeRecordService();
  TimeRecord _todayRecord = TimeRecord();
  Duration _weekBalance = Duration.zero;
  Duration _weekWorkedHours = Duration.zero;
  int _weekWorkedDays = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTodayRecord();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1, end: 1.025).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppSettingsService.current;
    final engine = WorkScheduleEngine(settings.workDayRule);
    final dayType = engine.getDayType(_todayRecord.date);
    final shift = engine.getShiftForDate(_todayRecord.date);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DashboardHeader(),
                      const SizedBox(height: 14),
                      DashboardInsightsPanel(
                        todayRecord: _todayRecord,
                        weekWorkedDays: _weekWorkedDays,
                        weekWorkedHours: _weekWorkedHours,
                        weekBalance: _weekBalance,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : PunchButton(
                                canPunch:
                                    !_isLoading && _isWorkingDay(dayType) && !_isDayFinalized,
                                isDayFinalized: _isDayFinalized,
                                onPressed:
                                    !_isLoading && _isWorkingDay(dayType) && !_isDayFinalized
                                    ? _recordNow
                                    : null,
                                pulseAnimation: _pulseAnimation,
                              ),
                      ),
                      const SizedBox(height: 28),
                      if (_isWorkingDay(dayType)) ...[
                        TimeRecordCard(
                          label: 'Entrada',
                          value: _todayRecord.entryTime,
                          expected: _formatExpectedTime(
                            shift?.startHour ?? settings.defaultEntryHour,
                            shift?.startMinute ?? settings.defaultEntryMinute,
                          ),
                          timeFormatter: _hourFormatter,
                          onTap: _isLoading
                              ? null
                              : () =>
                                    _editRecordTime(_RecordField.entry, _todayRecord.entryTime),
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
                          onTap: _isLoading
                              ? null
                              : () => _editRecordTime(_RecordField.exit, _todayRecord.exitTime),
                        ),
                        const SizedBox(height: 14),
                        _buildNoteSection(theme),
                      ] else
                        _buildSpecialDayMessage(theme, dayType),
                      const Spacer(),
                      Align(
                        child: TextButton(
                          onPressed: _isLoading || !_isWorkingDay(dayType)
                              ? null
                              : _fillWithDefaultSchedule,
                          child: const Text('Preencher com horários padrões'),
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildSpecialDayMessage(ThemeData theme, WorkDayType dayType) {
    final message = switch (dayType) {
      WorkDayType.holiday => 'Aproveite seu feriado!',
      WorkDayType.compensatoryDayOff => 'Aproveite sua folga compensatória!',
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

  Widget _buildNoteSection(ThemeData theme) {
    return TextButton.icon(
      onPressed: _isLoading ? null : _showNoteDialog,
      icon: const Icon(Icons.edit_note_rounded),
      label: Text(_todayRecord.hasNote ? 'Editar observação' : 'Adicionar observação'),
    );
  }

  Future<void> _loadTodayRecord() async {
    setState(() => _isLoading = true);
    try {
      final record = await _timeRecordService.getTodayRecord();
      final summary = await _loadWeekSummary();
      if (!mounted) {
        return;
      }
      setState(() {
        _todayRecord = record;
        _weekBalance = summary.balance;
        _weekWorkedHours = summary.workedHours;
        _weekWorkedDays = summary.workedDays;
      });
      unawaited(syncHomeWidgetStatus());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _recordNow() async {
    setState(() => _isLoading = true);
    try {
      final result = await _timeRecordService.recordCurrentTime();
      if (!mounted) {
        return;
      }
      setState(() => _todayRecord = result.record);
      await _refreshWeekSummary();
      unawaited(syncHomeWidgetStatus());
      widget.onHistoryRefreshRequested();
      SnackBarHelper.showSuccess(context, 'Ponto registrado com sucesso!');
    } catch (_) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Não foi possível registrar o ponto.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fillWithDefaultSchedule() async {
    setState(() => _isLoading = true);
    try {
      final filledRecord = await _timeRecordService.fillWithDefaultSchedule(date: DateTime.now());
      if (!mounted) {
        return;
      }
      setState(() => _todayRecord = filledRecord);
      await _refreshWeekSummary();
      unawaited(syncHomeWidgetStatus());
      widget.onHistoryRefreshRequested();
      SnackBarHelper.showSuccess(context, 'Horários padrões aplicados!');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      setState(() {});
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
      setState(() {});
      widget.onHistoryRefreshRequested();
    }
  }

  String _formatExpectedTime(int hour, int minute) {
    return _hourFormatter.format(DateTime(2000, 1, 1, hour, minute));
  }

  DateFormat get _hourFormatter => DateFormat('HH:mm');

  bool get _isDayFinalized => _todayRecord.entryTime != null && _todayRecord.exitTime != null;

  Future<void> _refreshWeekSummary() async {
    final summary = await _loadWeekSummary();
    if (!mounted) {
      return;
    }
    setState(() {
      _weekBalance = summary.balance;
      _weekWorkedHours = summary.workedHours;
      _weekWorkedDays = summary.workedDays;
    });
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
    return _WeeklySummary(balance: balance, workedHours: workedHours, workedDays: workedDays);
  }
}

class _WeeklySummary {
  const _WeeklySummary({
    required this.balance,
    required this.workedHours,
    required this.workedDays,
  });

  final Duration balance;
  final Duration workedHours;
  final int workedDays;
}
