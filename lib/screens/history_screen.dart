import 'dart:async';

import 'package:auratime/core/ui/snackbar_helper.dart';
import 'package:auratime/domain/work_schedule/work_schedule_engine.dart';
import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:auratime/services/pdf_report_service.dart';
import 'package:auratime/services/time_record_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.refreshListenable});

  final ValueListenable<int> refreshListenable;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TimeRecordService _timeRecordService = TimeRecordService();
  final DateFormat _dateFormatter = DateFormat("d 'de' MMMM", 'pt_BR');
  final DateFormat _shortDateFormatter = DateFormat('dd/MM', 'pt_BR');
  final DateFormat _timeFormatter = DateFormat('HH:mm', 'pt_BR');
  List<TimeRecord> _allRecords = const [];
  List<TimeRecord> _visibleRecords = const [];
  List<_HistoryRowViewModel> _rowViewModels = const [];
  Duration _periodTotalWorked = Duration.zero;
  Duration _periodTotalBalance = Duration.zero;
  int _positiveDayCount = 0;
  int _negativeDayCount = 0;
  late WorkScheduleEngine _scheduleEngine;
  _HistoryFilter _selectedFilter = _HistoryFilter.currentMonth;
  DateTimeRange? _customRange;
  bool _isLoading = true;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _scheduleEngine = WorkScheduleEngine(AppSettingsService.current.workDayRule);
    AppSettingsService.settingsListenable.addListener(_onSettingsChanged);
    _loadHistory();
    widget.refreshListenable.addListener(_onExternalRefreshRequested);
  }

  void _onSettingsChanged() {
    _scheduleEngine = WorkScheduleEngine(AppSettingsService.current.workDayRule);
    if (mounted) {
      setState(_recomputeDisplayData);
    }
  }

  @override
  void didUpdateWidget(covariant HistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshListenable != widget.refreshListenable) {
      oldWidget.refreshListenable.removeListener(_onExternalRefreshRequested);
      widget.refreshListenable.addListener(_onExternalRefreshRequested);
    }
  }

  @override
  void dispose() {
    AppSettingsService.settingsListenable.removeListener(_onSettingsChanged);
    widget.refreshListenable.removeListener(_onExternalRefreshRequested);
    super.dispose();
  }

  void _recomputeDisplayData() {
    final range = _selectedDateRange;
    final filtered = _allRecords
        .where((record) => _isWithinRange(record.date, range))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    _visibleRecords = filtered;

    var totalWorked = Duration.zero;
    var totalBalance = Duration.zero;
    var positiveDays = 0;
    var negativeDays = 0;
    for (final record in filtered) {
      totalWorked += record.totalWorkedHours;
      totalBalance += record.balance;
      if (record.balance.inMinutes > 0) {
        positiveDays++;
      } else if (record.balance.inMinutes < 0) {
        negativeDays++;
      }
    }
    _periodTotalWorked = totalWorked;
    _periodTotalBalance = totalBalance;
    _positiveDayCount = positiveDays;
    _negativeDayCount = negativeDays;
    _rowViewModels = filtered
        .map(
          (r) => _HistoryRowViewModel.from(
            r,
            _scheduleEngine,
            _dateFormatter,
            _timeFormatter,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _isLoading
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text('Histórico', style: theme.textTheme.headlineMedium),
                          const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text('Histórico', style: theme.textTheme.headlineMedium),
                          const SizedBox(height: 6),
                          _buildFilterSection(theme),
                          const SizedBox(height: 8),
                          _buildSummaryCard(theme),
                          const SizedBox(height: 8),
                          Expanded(child: _buildRefreshableHistoryList(theme)),
                        ],
                      ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: SafeArea(
              minimum: const EdgeInsets.only(right: 8, bottom: 8),
              child: Padding(
                padding: const EdgeInsets.only(right: 4, bottom: 4),
                child: _buildPdfFab(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PDF action pinned above the tab content bottom edge (clear of list cards).
  /// Uses [Stack] placement instead of [Scaffold.floatingActionButton] so layout
  /// stays correct inside the shell [IndexedStack].
  Widget _buildPdfFab(ThemeData theme) {
    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(18),
      child: FloatingActionButton.extended(
        heroTag: 'history_pdf_report_fab',
        tooltip: 'Relatório PDF',
        elevation: 0,
        highlightElevation: 0,
        onPressed: _isLoading || _isGeneratingReport ? null : _generatePdfReport,
        icon: _isGeneratingReport
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.onSurface,
                ),
              )
            : Icon(Icons.picture_as_pdf_rounded, color: theme.colorScheme.secondary),
        label: const Text('Relatório PDF'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.35),
          ),
        ),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundColor: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    final isCompact = MediaQuery.sizeOf(context).width < 390;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              _buildCompactSegment(
                theme: theme,
                value: _HistoryFilter.currentMonth,
                label: 'Mês',
                isCompact: isCompact,
              ),
              _buildCompactSegment(
                theme: theme,
                value: _HistoryFilter.last7Days,
                label: '7d',
                isCompact: isCompact,
              ),
              _buildCompactSegment(
                theme: theme,
                value: _HistoryFilter.last30Days,
                label: '30d',
                isCompact: isCompact,
              ),
              _buildCompactSegment(
                theme: theme,
                value: _HistoryFilter.customRange,
                label: isCompact ? 'Período' : 'Personaliz.',
                isCompact: isCompact,
              ),
            ],
          ),
        ),
        if (_selectedFilter == _HistoryFilter.customRange) ...[
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await _pickCustomRange();
              if (picked == null) {
                return;
              }
              setState(() {
                _customRange = picked;
                _recomputeDisplayData();
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _customRange == null
                    ? 'Selecionar intervalo'
                    : '${_shortDateFormatter.format(_customRange!.start)} - ${_shortDateFormatter.format(_customRange!.end)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactSegment({
    required ThemeData theme,
    required _HistoryFilter value,
    required String label,
    required bool isCompact,
  }) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (value == _HistoryFilter.customRange) {
            final picked = await _pickCustomRange();
            if (picked == null) {
              return;
            }
            setState(() {
              _selectedFilter = _HistoryFilter.customRange;
              _customRange = picked;
              _recomputeDisplayData();
            });
            return;
          }
          setState(() {
            _selectedFilter = value;
            _recomputeDisplayData();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: isCompact ? 11.5 : 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    final records = _visibleRecords;
    final totalWorked = _periodTotalWorked;
    final balance = _periodTotalBalance;
    final positiveDays = _positiveDayCount;
    final negativeDays = _negativeDayCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo do período', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    theme: theme,
                    label: 'Dias',
                    value: '${records.length}',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    theme: theme,
                    label: 'Horas',
                    value: _formatDuration(totalWorked),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    theme: theme,
                    label: 'Saldo',
                    value: _formatSignedDuration(balance),
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    theme: theme,
                    label: 'Pos./Neg.',
                    value: '$positiveDays / $negativeDays',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Future<void> _loadHistory() async {
    return _loadHistoryInternal(showLoading: true);
  }

  Future<void> _refreshHistory() async {
    await _loadHistoryInternal(showLoading: false);
  }

  Future<void> _loadHistoryInternal({required bool showLoading}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final records = await _timeRecordService.getAllRecords();
      if (!mounted) {
        return;
      }
      setState(() {
        _allRecords = records;
        _recomputeDisplayData();
      });
    } catch (_) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Não foi possível carregar o histórico.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generatePdfReport() async {
    final records = _visibleRecords;
    if (records.isEmpty) {
      SnackBarHelper.showWarning(
        context,
        'Não há registros para gerar relatório no momento.',
      );
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      await PdfReportService.generateAndPrintReport(
        records,
        _periodTotalBalance,
        _currentPeriodLabel(),
        _currentPeriodFileLabel(),
        AppSettingsService.current.userName,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes.abs();
    final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  String _formatSignedDuration(
    Duration duration, {
    bool withHoursLabel = false,
  }) {
    final sign = duration.inMinutes >= 0 ? '+' : '-';
    final timeText = _formatDuration(duration);
    if (withHoursLabel) {
      return '$sign $timeText hrs';
    }
    return '$sign $timeText';
  }

  String _capitalize(String text) {
    if (text.isEmpty) {
      return text;
    }
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  Widget _buildRefreshableHistoryList(ThemeData theme) {
    final rows = _rowViewModels;

    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: rows.isEmpty
          ? ListView(
              padding: const EdgeInsets.only(bottom: 104),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Text(
                      'Nenhum registro salvo ainda.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 104),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: rows.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final row = rows[index];
                return RepaintBoundary(
                  child: _HistoryRecordTile(theme: theme, row: row),
                );
              },
            ),
    );
  }

  void _onExternalRefreshRequested() {
    unawaited(_loadHistoryInternal(showLoading: false));
  }

  DateTimeRange get _selectedDateRange {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_selectedFilter) {
      case _HistoryFilter.currentMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: end);
      case _HistoryFilter.last7Days:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        return DateTimeRange(start: start, end: end);
      case _HistoryFilter.last30Days:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        return DateTimeRange(start: start, end: end);
      case _HistoryFilter.customRange:
        return _customRange ??
            DateTimeRange(start: DateTime(now.year, now.month, 1), end: end);
    }
  }

  bool _isWithinRange(DateTime date, DateTimeRange range) {
    final normalized = DateTime(date.year, date.month, date.day);
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  Future<DateTimeRange?> _pickCustomRange() async {
    final now = DateTime.now();
    final initial =
        _customRange ??
        DateTimeRange(
          start: DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(const Duration(days: 6)),
          end: DateTime(now.year, now.month, now.day),
        );
    final theme = Theme.of(context);
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: initial,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            dialogTheme: theme.dialogTheme.copyWith(
              insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            ),
            datePickerTheme: _historyDatePickerTheme(theme),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  String _currentPeriodLabel() {
    final range = _selectedDateRange;
    switch (_selectedFilter) {
      case _HistoryFilter.currentMonth:
        return 'Mês atual (${DateFormat('MMMM yyyy', 'pt_BR').format(range.start)})';
      case _HistoryFilter.last7Days:
        return 'Últimos 7 dias (${_shortDateFormatter.format(range.start)} a ${_shortDateFormatter.format(range.end)})';
      case _HistoryFilter.last30Days:
        return 'Últimos 30 dias (${_shortDateFormatter.format(range.start)} a ${_shortDateFormatter.format(range.end)})';
      case _HistoryFilter.customRange:
        return 'Período personalizado (${_shortDateFormatter.format(range.start)} a ${_shortDateFormatter.format(range.end)})';
    }
  }

  String _currentPeriodFileLabel() {
    final range = _selectedDateRange;
    switch (_selectedFilter) {
      case _HistoryFilter.currentMonth:
        return _capitalize(
          DateFormat('MMMM_yyyy', 'pt_BR').format(range.start),
        );
      case _HistoryFilter.last7Days:
        return 'Ultimos_7_Dias';
      case _HistoryFilter.last30Days:
        return 'Ultimos_30_Dias';
      case _HistoryFilter.customRange:
        final start = DateFormat('dd-MM-yyyy', 'pt_BR').format(range.start);
        final end = DateFormat('dd-MM-yyyy', 'pt_BR').format(range.end);
        return '${start}_a_$end';
    }
  }

}

/// Dark, AuraTime-aligned contrast for range selection (readable endpoints + soft span).
DatePickerThemeData _historyDatePickerTheme(ThemeData theme) {
  final cs = theme.colorScheme;
  return DatePickerThemeData(
    backgroundColor: cs.surface,
    elevation: 0,
    shadowColor: Colors.transparent,
    headerBackgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
    headerForegroundColor: cs.onSurface,
    headerHelpStyle: theme.textTheme.titleSmall?.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w600,
    ),
    weekdayStyle: theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    ),
    dayStyle: theme.textTheme.bodyMedium?.copyWith(
      color: cs.onSurface,
      fontWeight: FontWeight.w600,
    ),
    dayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return cs.onSurface.withValues(alpha: 0.38);
      }
      if (states.contains(WidgetState.selected)) {
        return cs.onPrimary;
      }
      return cs.onSurface;
    }),
    dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return cs.primary;
      }
      return null;
    }),
    todayForegroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return cs.onPrimary;
      }
      return cs.secondary;
    }),
    todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return cs.primary;
      }
      return cs.secondary.withValues(alpha: 0.14);
    }),
    todayBorder: BorderSide(
      color: cs.secondary.withValues(alpha: 0.7),
      width: 1,
    ),
    rangeSelectionBackgroundColor: cs.primary.withValues(alpha: 0.22),
    rangeSelectionOverlayColor: WidgetStateProperty.all(
      cs.primary.withValues(alpha: 0.10),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: cs.outline.withValues(alpha: 0.45)),
    ),
  );
}

class _HistoryRowViewModel {
  const _HistoryRowViewModel({
    required this.record,
    required this.dateTitle,
    required this.statusText,
    required this.balanceStr,
    required this.balanceColor,
    required this.workedStr,
    required this.entryStr,
    required this.exitStr,
    required this.statusColor,
    required this.statusBackground,
    this.note,
  });

  final TimeRecord record;
  final String dateTitle;
  final String statusText;
  final String balanceStr;
  final Color balanceColor;
  final String workedStr;
  final String entryStr;
  final String exitStr;
  final Color statusColor;
  final Color statusBackground;
  final String? note;

  factory _HistoryRowViewModel.from(
    TimeRecord record,
    WorkScheduleEngine engine,
    DateFormat dateFormatter,
    DateFormat timeFormatter,
  ) {
    final workDayType = engine.getDayType(record.date);
    final dailyBalance = record.balance;
    final isPositive = dailyBalance.inMinutes >= 0;
    final balanceColor = isPositive
        ? const Color(0xFF56F09B)
        : const Color(0xFFFF8A80);
    final statusText = engine.getDisplayDayLabel(record.date);
    final statusColor = _historyWorkDayTypeColor(workDayType);
    final statusBackground = statusColor.withValues(alpha: 0.18);

    String capitalize(String text) {
      if (text.isEmpty) {
        return text;
      }
      return '${text[0].toUpperCase()}${text.substring(1)}';
    }

    String formatDuration(Duration duration) {
      final totalMinutes = duration.inMinutes.abs();
      final hours = (totalMinutes ~/ 60).toString().padLeft(2, '0');
      final minutes = (totalMinutes % 60).toString().padLeft(2, '0');
      return '$hours:$minutes';
    }

    String formatSignedDuration(Duration duration) {
      final sign = duration.inMinutes >= 0 ? '+' : '-';
      return '$sign ${formatDuration(duration)}';
    }

    String formatPunch(DateTime? time) {
      if (time == null) {
        return '--:--';
      }
      return timeFormatter.format(time);
    }

    return _HistoryRowViewModel(
      record: record,
      dateTitle: capitalize(dateFormatter.format(record.date)),
      statusText: statusText,
      balanceStr: formatSignedDuration(dailyBalance),
      balanceColor: balanceColor,
      workedStr: formatDuration(record.totalWorkedHours),
      entryStr: formatPunch(record.entryTime),
      exitStr: formatPunch(record.exitTime),
      statusColor: statusColor,
      statusBackground: statusBackground,
      note: record.hasNote ? record.note!.trim() : null,
    );
  }
}

Color _historyWorkDayTypeColor(WorkDayType dayType) {
  switch (dayType) {
    case WorkDayType.regular:
      return const Color(0xFF8BE9FD);
    case WorkDayType.saturdayCompensation:
      return const Color(0xFFFFC857);
    case WorkDayType.holiday:
      return const Color(0xFF72D7FF);
    case WorkDayType.holidayWorkedSwap:
      return const Color(0xFFA29BFE);
    case WorkDayType.compensatoryDayOff:
      return const Color(0xFFFFB199);
  }
}

class _HistoryRecordTile extends StatelessWidget {
  const _HistoryRecordTile({
    required this.theme,
    required this.row,
  });

  final ThemeData theme;
  final _HistoryRowViewModel row;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: row.statusBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    row.statusText,
                    style: TextStyle(
                      color: row.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    row.dateTitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      row.balanceStr,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: row.balanceColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      row.workedStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _HistoryPunchInfo(
                    theme: theme,
                    icon: Icons.login_rounded,
                    label: 'Entrada',
                    value: row.entryStr,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HistoryPunchInfo(
                    theme: theme,
                    icon: Icons.logout_rounded,
                    label: 'Saída',
                    value: row.exitStr,
                  ),
                ),
              ],
            ),
            if (row.note != null) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.comment_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      row.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryPunchInfo extends StatelessWidget {
  const _HistoryPunchInfo({
    required this.theme,
    required this.icon,
    required this.label,
    required this.value,
  });

  final ThemeData theme;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _HistoryFilter { currentMonth, last7Days, last30Days, customRange }
