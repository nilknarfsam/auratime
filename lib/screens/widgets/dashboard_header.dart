import 'dart:async';

import 'package:auratime/services/app_settings_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardHeader extends StatefulWidget {
  const DashboardHeader({super.key});

  @override
  State<DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<DashboardHeader> {
  final DateFormat _longDateFormatter = DateFormat(
    "EEEE, d 'de' MMMM",
    'pt_BR',
  );
  final DateFormat _clockFormatter = DateFormat('HH:mm:ss');
  late final Timer _clockTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppSettingsService.current;
    final greeting = _greeting(_now, settings.userName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: theme.textTheme.headlineMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _clockFormatter.format(_now),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _longDateFormatter.format(_now),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _greeting(DateTime date, String userName) {
    final normalizedName = userName.trim();
    if (normalizedName.isEmpty) {
      return 'Bem-vindo';
    }
    if (date.hour < 12) {
      return 'Bom dia, $normalizedName';
    }
    if (date.hour < 18) {
      return 'Boa tarde, $normalizedName';
    }
    return 'Boa noite, $normalizedName';
  }
}
