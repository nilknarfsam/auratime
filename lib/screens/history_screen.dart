import 'package:auratime/models/time_record.dart';
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
  List<TimeRecord> _records = const [];
  Duration _totalBalance = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _records.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildTotalBalanceCard(theme);
        }

        if (_records.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text(
                'Nenhum registro salvo ainda.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        }

        final record = _records[index - 1];
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
            child: Row(
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
          ),
        );
      },
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
    final records = await _timeRecordService.getAllRecords();
    final totalBalance = await _timeRecordService.calculateTotalBalance();
    if (!mounted) {
      return;
    }
    setState(() {
      _records = records;
      _totalBalance = totalBalance;
      _isLoading = false;
    });
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
}
