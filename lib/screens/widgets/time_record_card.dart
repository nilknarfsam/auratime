import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeRecordCard extends StatelessWidget {
  const TimeRecordCard({
    super.key,
    required this.label,
    required this.value,
    required this.expected,
    required this.timeFormatter,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final String expected;
  final DateFormat timeFormatter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFilled = value != null;
    final iconColor = isFilled
        ? theme.colorScheme.secondary
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Row(
            children: [
              Icon(
                isFilled
                    ? Icons.check_circle_rounded
                    : Icons.access_time_rounded,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  isFilled && value != null
                      ? timeFormatter.format(value!)
                      : 'Previsto: $expected',
                  textAlign: TextAlign.end,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: isFilled
                      ? theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        )
                      : theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
