import 'dart:async';

import 'package:auratime/core/ui/snackbar_helper.dart';
import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:auratime/services/pdf_report_service.dart';
import 'package:auratime/services/time_record_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.refreshListenable,
  });

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
  _HistoryFilter _selectedFilter = _HistoryFilter.currentMonth;
  DateTimeRange? _customRange;
  bool _isLoading = true;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    widget.refreshListenable.addListener(_onExternalRefreshRequested);
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
    widget.refreshListenable.removeListener(_onExternalRefreshRequested);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _isLoading
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Histórico',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Histórico',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 14),
                    _buildFilterSection(theme),
                    const SizedBox(height: 12),
                    _buildSummaryCard(theme),
                    const SizedBox(height: 12),
                    Expanded(child: _buildRefreshableHistoryList(theme)),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'history_pdf_report_fab',
        onPressed: _isLoading || _isGeneratingReport ? null : _generatePdfReport,
        icon: _isGeneratingReport
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf_rounded),
        label: const Text('Relatório PDF'),
      ),
    );
  }

  Widget _buildHistoryRecordCard(ThemeData theme, TimeRecord record) {
    final dailyBalance = record.balance;
    final isPositive = dailyBalance.inMinutes >= 0;
    final balanceColor = isPositive ? const Color(0xFF56F09B) : const Color(0xFFFF8A80);
    final statusText = _dayTypeLabel(record.dayType);
    final statusColor = _dayTypeColor(record.dayType);
    final statusBackground = statusColor.withValues(alpha: 0.18);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _capitalize(_dateFormatter.format(record.date)),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatSignedDuration(dailyBalance),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(record.totalWorkedHours),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildPunchInfo(
                    theme: theme,
                    icon: Icons.login_rounded,
                    label: 'Entrada',
                    value: _formatPunch(record.entryTime),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPunchInfo(
                    theme: theme,
                    icon: Icons.logout_rounded,
                    label: 'Saída',
                    value: _formatPunch(record.exitTime),
                  ),
                ),
              ],
            ),
            if (record.hasNote) ...[
              const SizedBox(height: 8),
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
                      record.note!.trim(),
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

  Widget _buildPunchInfo({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
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

  Widget _buildFilterSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<_HistoryFilter>(
          segments: const [
            ButtonSegment(
              value: _HistoryFilter.currentMonth,
              label: Text('Mês atual'),
            ),
            ButtonSegment(
              value: _HistoryFilter.last7Days,
              label: Text('7 dias'),
            ),
            ButtonSegment(
              value: _HistoryFilter.last30Days,
              label: Text('30 dias'),
            ),
            ButtonSegment(
              value: _HistoryFilter.customRange,
              label: Text('Personalizado'),
            ),
          ],
          selected: {_selectedFilter},
          showSelectedIcon: false,
          onSelectionChanged: (selected) async {
            final next = selected.first;
            if (next == _HistoryFilter.customRange) {
              final picked = await _pickCustomRange();
              if (picked == null) {
                return;
              }
              setState(() {
                _selectedFilter = _HistoryFilter.customRange;
                _customRange = picked;
              });
              return;
            }
            setState(() {
              _selectedFilter = next;
            });
          },
        ),
        if (_selectedFilter == _HistoryFilter.customRange) ...[
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final picked = await _pickCustomRange();
              if (picked == null) {
                return;
              }
              setState(() {
                _customRange = picked;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
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

  Widget _buildSummaryCard(ThemeData theme) {
    final records = _filteredRecords;
    final totalWorked = _totalWorkedPeriod;
    final balance = _totalBalancePeriod;
    final positiveDays = records.where((r) => r.balance.inMinutes > 0).length;
    final negativeDays = records.where((r) => r.balance.inMinutes < 0).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo do período', style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
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
            const SizedBox(height: 8),
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
      });
    } catch (_) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Não foi possível carregar o histórico.');
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
    final records = _filteredRecords;
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
        _totalBalancePeriod,
        _currentPeriodLabel(),
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

  String _formatSignedDuration(Duration duration, {bool withHoursLabel = false}) {
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
    final records = _filteredRecords;

    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: records.isEmpty
          ? ListView(
              padding: const EdgeInsets.only(bottom: 100),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
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
              padding: const EdgeInsets.only(bottom: 100),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildHistoryRecordCard(theme, records[index]);
              },
            ),
    );
  }

  void _onExternalRefreshRequested() {
    unawaited(_loadHistoryInternal(showLoading: false));
  }

  List<TimeRecord> get _filteredRecords {
    final range = _selectedDateRange;
    return _allRecords
        .where((record) => _isWithinRange(record.date, range))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Duration get _totalWorkedPeriod {
    Duration total = Duration.zero;
    for (final record in _filteredRecords) {
      total += record.totalWorkedHours;
    }
    return total;
  }

  Duration get _totalBalancePeriod {
    Duration total = Duration.zero;
    for (final record in _filteredRecords) {
      total += record.balance;
    }
    return total;
  }

  DateTimeRange get _selectedDateRange {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_selectedFilter) {
      case _HistoryFilter.currentMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: end,
        );
      case _HistoryFilter.last7Days:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return DateTimeRange(start: start, end: end);
      case _HistoryFilter.last30Days:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
        return DateTimeRange(start: start, end: end);
      case _HistoryFilter.customRange:
        return _customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: end,
            );
    }
  }

  bool _isWithinRange(DateTime date, DateTimeRange range) {
    final normalized = DateTime(date.year, date.month, date.day);
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  Future<DateTimeRange?> _pickCustomRange() async {
    final now = DateTime.now();
    final initial = _customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day).subtract(
            const Duration(days: 6),
          ),
          end: DateTime(now.year, now.month, now.day),
        );
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      initialDateRange: initial,
      locale: const Locale('pt', 'BR'),
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

  String _formatPunch(DateTime? time) {
    if (time == null) {
      return '--:--';
    }
    return _timeFormatter.format(time);
  }

  String _dayTypeLabel(DayType dayType) {
    switch (dayType) {
      case DayType.regular:
        return 'Normal';
      case DayType.holiday:
        return 'Feriado';
      case DayType.dayOff:
        return 'Folga';
    }
  }

  Color _dayTypeColor(DayType dayType) {
    switch (dayType) {
      case DayType.regular:
        return const Color(0xFF8BE9FD);
      case DayType.holiday:
        return const Color(0xFF72D7FF);
      case DayType.dayOff:
        return const Color(0xFFFFB199);
    }
  }

}

enum _HistoryFilter {
  currentMonth,
  last7Days,
  last30Days,
  customRange,
}
