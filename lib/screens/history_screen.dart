import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/pdf_report_service.dart';
import 'package:auratime/services/time_record_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TimeRecordService _timeRecordService = TimeRecordService();
  final DateFormat _dateFormatter = DateFormat("d 'de' MMMM", 'pt_BR');
  final DateFormat _monthKeyFormatter = DateFormat('MM/yyyy', 'pt_BR');
  final DateFormat _monthLabelFormatter = DateFormat('MMMM yyyy', 'pt_BR');
  List<TimeRecord> _records = const [];
  Duration _totalBalance = Duration.zero;
  bool _isLoading = true;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
                    _buildTotalBalanceCard(theme),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _records.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.only(bottom: 100),
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
                              itemCount: _records.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildHistoryRecordCard(theme, _records[index]);
                              },
                            ),
                    ),
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
    final hasAllPunches = record.entryTime != null && record.exitTime != null;
    final statusColor = hasAllPunches ? Colors.greenAccent : Colors.amberAccent;
    final isHoliday = record.dayType == DayType.holiday;
    final isDayOff = record.dayType == DayType.dayOff;
    final balanceColor = isHoliday
        ? theme.colorScheme.onSurfaceVariant
        : dailyBalance.inMinutes >= 0
            ? Colors.greenAccent
            : Colors.redAccent;
    final balanceText = isHoliday ? '00:00' : _formatSignedDuration(dailyBalance);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isHoliday || isDayOff)
                  _buildDayTypeBadge(record.dayType)
                else
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: 12),
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
                      _formatDuration(record.totalWorkedHours),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      balanceText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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

  Widget _buildDayTypeBadge(DayType dayType) {
    final isHoliday = dayType == DayType.holiday;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHoliday
            ? const Color(0xFF2D9CDB).withValues(alpha: 0.22)
            : const Color(0xFFFF8A65).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isHoliday ? 'Feriado' : 'Folga',
        style: TextStyle(
          color: isHoliday ? const Color(0xFF72D7FF) : const Color(0xFFFFB199),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(ThemeData theme) {
    final isPositive = _totalBalance.inMinutes >= 0;
    final balanceColor = isPositive ? Colors.greenAccent : Colors.redAccent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Saldo Acumulado',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Text(
              _formatSignedDuration(_totalBalance, withHoursLabel: true),
              style: theme.textTheme.titleMedium?.copyWith(
                color: balanceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadHistory() async {
    try {
      final records = await _timeRecordService.getAllRecords();
      final totalBalance = await _timeRecordService.calculateTotalBalance();
      if (!mounted) {
        return;
      }
      setState(() {
        _records = records;
        _totalBalance = totalBalance;
      });
    } catch (_) {
      if (mounted) {
        _showErrorSnackBar('Não foi possível carregar o histórico.');
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
    final availableMonths = _extractAvailableMonths();
    if (availableMonths.isEmpty) {
      return;
    }

    final selectedMonth = await showModalBottomSheet<_MonthOption>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exportar Relatório',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableMonths.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final option = availableMonths[index];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                      leading: const Icon(Icons.calendar_month_rounded),
                      title: Text(option.label),
                      onTap: () => Navigator.of(context).pop(option),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedMonth == null) {
      return;
    }

    final monthlyRecords = _records
        .where(
          (record) =>
              record.date.year == selectedMonth.year &&
              record.date.month == selectedMonth.month,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    Duration monthlyBalance = Duration.zero;
    for (final record in monthlyRecords) {
      monthlyBalance += record.balance;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      await PdfReportService.generateAndPrintReport(
        monthlyRecords,
        monthlyBalance,
        selectedMonth.label,
        'Franklin',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  List<_MonthOption> _extractAvailableMonths() {
    final monthMap = <String, _MonthOption>{};
    for (final record in _records) {
      final key = _monthKeyFormatter.format(record.date);
      monthMap.putIfAbsent(
        key,
        () => _MonthOption(
          key: key,
          year: record.date.year,
          month: record.date.month,
          label: _capitalize(_monthLabelFormatter.format(record.date)),
        ),
      );
    }

    final months = monthMap.values.toList()
      ..sort((a, b) {
        if (a.year != b.year) {
          return b.year.compareTo(a.year);
        }
        return b.month.compareTo(a.month);
      });

    return months;
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

  void _showErrorSnackBar(String message) {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: theme.colorScheme.onErrorContainer,
            fontSize: 14,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _MonthOption {
  const _MonthOption({
    required this.key,
    required this.year,
    required this.month,
    required this.label,
  });

  final String key;
  final int year;
  final int month;
  final String label;
}
