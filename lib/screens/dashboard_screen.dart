import 'package:flutter/material.dart';
import 'package:auratime/models/time_record.dart';
import 'package:auratime/services/time_record_service.dart';
import 'package:intl/intl.dart';

enum _RecordField { entry, exit }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final TimeRecordService _timeRecordService = TimeRecordService();
  final DateFormat _longDateFormatter = DateFormat(
    "EEEE, d 'de' MMMM",
    'pt_BR',
  );
  final DateFormat _timeFormatter = DateFormat('HH:mm');
  TimeRecord _todayRecord = TimeRecord();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      _buildHeader(theme),
                      const SizedBox(height: 14),
                      _buildDayTypeSelector(theme),
                      const SizedBox(height: 24),
                      Center(
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : _buildPunchButton(theme),
                      ),
                      const SizedBox(height: 28),
                      if (_isRegularDay) ...[
                        _buildRecordCard(
                          theme: theme,
                          label: 'Entrada',
                          value: _todayRecord.entryTime,
                          field: _RecordField.entry,
                          expected: _formatExpectedTime(
                            TimeRecordService.defaultEntryHour,
                            TimeRecordService.defaultEntryMinute,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildRecordCard(
                          theme: theme,
                          label: 'Saída',
                          value: _todayRecord.exitTime,
                          field: _RecordField.exit,
                          expected: _formatExpectedTime(
                            TimeRecordService.defaultExitHour,
                            TimeRecordService.defaultExitMinute,
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          opacity: _shouldShowExitPrediction ? 1 : 0,
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                            child: _shouldShowExitPrediction
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: _buildPredictionBanner(theme),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildNoteSection(theme),
                      ] else
                        _buildSpecialDayMessage(theme),
                      const Spacer(),
                      Align(
                        child: TextButton(
                          onPressed: _isLoading ? null : _fillWithDefaultSchedule,
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

  @override
  void initState() {
    super.initState();
    _loadTodayRecord();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildHeader(ThemeData theme) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(now),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          _longDateFormatter.format(now),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildPunchButton(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;

    return ScaleTransition(
      scale: _pulseAnimation,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.45),
              blurRadius: 42,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: secondary.withValues(alpha: 0.22),
              blurRadius: 56,
              spreadRadius: 6,
            ),
          ],
        ),
        child: SizedBox(
          width: 220,
          height: 220,
          child: FloatingActionButton(
            heroTag: 'punch_now_button',
            elevation: 0,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: theme.colorScheme.onSurface,
            onPressed: _isLoading || !_isRegularDay ? null : _recordNow,
            shape: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Bater Ponto Agora',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordCard({
    required ThemeData theme,
    required String label,
    required DateTime? value,
    required _RecordField field,
    required String expected,
  }) {
    final isFilled = value != null;
    final recordedTime = value;
    final iconColor =
        isFilled ? theme.colorScheme.secondary : theme.colorScheme.onSurfaceVariant;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isLoading ? null : () => _editRecordTime(field, value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Row(
            children: [
              Icon(
                isFilled ? Icons.check_circle_rounded : Icons.access_time_rounded,
                color: iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                isFilled && recordedTime != null
                    ? _timeFormatter.format(recordedTime)
                    : 'Previsto: $expected',
                style: isFilled
                    ? theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      )
                    : theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionBanner(ThemeData theme) {
    final predictedExit = _todayRecord.predictedExitTime;
    if (predictedExit == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flag_circle_rounded,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saída prevista para: ${_timeFormatter.format(predictedExit)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jornada de 8h48m + 1h de almoço',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTypeSelector(ThemeData theme) {
    return SegmentedButton<DayType>(
      segments: const [
        ButtonSegment(value: DayType.regular, label: Text('Dia Normal')),
        ButtonSegment(value: DayType.holiday, label: Text('Feriado')),
        ButtonSegment(value: DayType.dayOff, label: Text('Folga')),
      ],
      selected: {_todayRecord.dayType},
      showSelectedIcon: false,
      onSelectionChanged: _isLoading
          ? null
          : (selection) {
              final selectedDayType = selection.first;
              _onDayTypeChanged(selectedDayType);
            },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return theme.colorScheme.primary.withValues(alpha: 0.22);
          }
          return theme.colorScheme.surface;
        }),
        foregroundColor: WidgetStateProperty.all(theme.colorScheme.onSurface),
      ),
    );
  }

  Widget _buildSpecialDayMessage(ThemeData theme) {
    final isHoliday = _todayRecord.dayType == DayType.holiday;
    final message = isHoliday
        ? 'Aproveite seu Feriado!'
        : 'Aproveite sua Folga! (-08:48h no banco)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildNoteSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_todayRecord.hasNote)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _todayRecord.note!.trim(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: _isLoading ? null : _showNoteDialog,
          icon: const Icon(Icons.edit_note_rounded),
          label: Text(_todayRecord.hasNote ? 'Editar Observação' : 'Adicionar Observação'),
        ),
      ],
    );
  }

  Future<void> _loadTodayRecord() async {
    setState(() {
      _isLoading = true;
    });
    final record = await _timeRecordService.getTodayRecord();
    if (!mounted) {
      return;
    }
    setState(() {
      _todayRecord = record;
      _isLoading = false;
    });
  }

  Future<void> _recordNow() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final updatedRecord = await _timeRecordService.recordCurrentTime();
      if (!mounted) {
        return;
      }
      setState(() {
        _todayRecord = updatedRecord;
        _isLoading = false;
      });
      _showFeedbackSnackBar('Ponto registrado com sucesso!');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fillWithDefaultSchedule() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final filledRecord = await _timeRecordService.fillWithDefaultSchedule(
        date: DateTime.now(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _todayRecord = filledRecord;
        _isLoading = false;
      });
      _showFeedbackSnackBar('Horários padrões aplicados!');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _onDayTypeChanged(DayType dayType) async {
    if (_todayRecord.dayType == dayType) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _todayRecord.dayType = dayType;
      final updatedRecord = await _timeRecordService.saveRecord(_todayRecord);
      if (!mounted) {
        return;
      }
      setState(() {
        _todayRecord = updatedRecord;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editRecordTime(_RecordField field, DateTime? currentValue) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentValue != null
          ? TimeOfDay(hour: currentValue.hour, minute: currentValue.minute)
          : TimeOfDay.now(),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              surface: theme.colorScheme.surface,
              onSurface: theme.colorScheme.onSurface,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: theme.colorScheme.surface,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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

    setState(() {
      _isLoading = true;
    });

    try {
      _applyTimeToField(field, selectedDateTime);
      final updatedRecord = await _timeRecordService.saveRecord(_todayRecord);
      if (!mounted) {
        return;
      }
      setState(() {
        _todayRecord = updatedRecord;
        _isLoading = false;
      });
      _showFeedbackSnackBar('Horário atualizado com sucesso!');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showNoteDialog() async {
    final rawNote = _todayRecord.note ?? '';
    final initialNote =
        rawNote.length > 150 ? rawNote.substring(0, 150) : rawNote;
    final controller = TextEditingController(text: initialNote);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Observação do dia'),
          content: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            maxLength: 150,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ex: Compensação de feriado',
              border: const OutlineInputBorder(),
              counterStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _todayRecord.note = result.isEmpty ? null : result;
      final updatedRecord = await _timeRecordService.saveRecord(_todayRecord);
      if (!mounted) {
        return;
      }
      setState(() {
        _todayRecord = updatedRecord;
        _isLoading = false;
      });
      _showFeedbackSnackBar('Observação atualizada com sucesso!');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyTimeToField(_RecordField field, DateTime value) {
    switch (field) {
      case _RecordField.entry:
        _todayRecord.entryTime = value;
        return;
      case _RecordField.exit:
        _todayRecord.exitTime = value;
        return;
    }
  }

  void _showFeedbackSnackBar(String message) {
    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _greeting(DateTime date) {
    if (date.hour < 12) {
      return 'Bom dia';
    }
    if (date.hour < 18) {
      return 'Boa tarde';
    }
    return 'Boa noite';
  }

  String _formatExpectedTime(int hour, int minute) {
    return _timeFormatter.format(DateTime(2000, 1, 1, hour, minute));
  }

  bool get _shouldShowExitPrediction {
    return _isRegularDay &&
        _todayRecord.entryTime != null &&
        _todayRecord.exitTime == null &&
        _todayRecord.predictedExitTime != null;
  }

  bool get _isRegularDay => _todayRecord.dayType == DayType.regular;
}
