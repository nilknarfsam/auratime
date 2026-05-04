import 'package:auratime/core/ui/snackbar_helper.dart';
import 'package:auratime/domain/work_schedule/work_schedule_models.dart';
import 'package:auratime/services/backup_service.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onSettingsSaved});

  final VoidCallback onSettingsSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _userNameController;
  late TimeOfDay _defaultEntryTime;
  late TimeOfDay _defaultExitTime;
  late Duration _lunchBreak;
  late Duration _dailyGoal;
  late ShiftType _defaultShiftType;
  late bool _saturdayCompensationEnabled;
  late WorkShift _customShift;
  late WorkShift _saturdayShift;
  late List<Holiday> _holidays;
  late List<CompanyCalendarRule> _companyRules;
  bool _isSaving = false;
  bool _isBackupBusy = false;

  @override
  void initState() {
    super.initState();
    final settings = AppSettingsService.current;
    _userNameController = TextEditingController(text: settings.userName);
    _defaultEntryTime = TimeOfDay(
      hour: settings.defaultEntryHour,
      minute: settings.defaultEntryMinute,
    );
    _defaultExitTime = TimeOfDay(
      hour: settings.defaultExitHour,
      minute: settings.defaultExitMinute,
    );
    _lunchBreak = settings.lunchBreakDuration;
    _dailyGoal = settings.dailyGoalDuration;
    _defaultShiftType = settings.workDayRule.defaultShiftType;
    _saturdayCompensationEnabled = settings.workDayRule.saturdayCompensationEnabled;
    _customShift = settings.workDayRule.customShift;
    _saturdayShift = settings.workDayRule.saturdayCompensationShift;
    _holidays = List<Holiday>.from(settings.workDayRule.holidays);
    _companyRules = List<CompanyCalendarRule>.from(
      settings.workDayRule.companyCalendarRules,
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Configurações', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Personalize seus dados e jornada padrão.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Perfil', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _userNameController,
                      maxLength: 40,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome do usuário',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jornada de trabalho',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Turno padrão'),
                      subtitle: Text(_shiftTypeLabel(_defaultShiftType)),
                      trailing: DropdownButton<ShiftType>(
                        value: _defaultShiftType,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _defaultShiftType = value;
                                });
                              },
                        items: ShiftType.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(_shiftTypeLabel(item)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Habilitar sábado compensação'),
                      value: _saturdayCompensationEnabled,
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _saturdayCompensationEnabled = value;
                              });
                            },
                    ),
                    _buildShiftEditor(
                      title: 'Turno customizado',
                      shift: _customShift,
                      onUpdate: (shift) {
                        setState(() {
                          _customShift = shift.copyWith(type: ShiftType.custom);
                        });
                      },
                    ),
                    _buildShiftEditor(
                      title: 'Turno de sábado compensação',
                      shift: _saturdayShift,
                      onUpdate: (shift) {
                        setState(() {
                          _saturdayShift = shift.copyWith(type: ShiftType.custom);
                        });
                      },
                    ),
                    const Divider(height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gerenciar calendário da empresa'),
                      subtitle: Text(
                        '${_holidays.length} feriados • ${_companyRules.length} regras',
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _isSaving ? null : _addHoliday,
                          child: const Text('Adicionar feriado'),
                        ),
                        OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _addCompanyRule(WorkDayType.holidayWorkedSwap),
                          child: const Text('Feriado trabalhado (troca)'),
                        ),
                        OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () =>
                                  _addCompanyRule(WorkDayType.compensatoryDayOff),
                          child: const Text('Folga compensatória'),
                        ),
                        OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () =>
                                  _addCompanyRule(WorkDayType.saturdayCompensation),
                          child: const Text('Dia de sábado compensado'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._buildCalendarRuleChips(theme),
                    const Divider(height: 20),
                    _buildTimeTile(
                      context: context,
                      label: 'Duração do almoço',
                      value: _formatDuration(_lunchBreak),
                      onTap: () => _pickDuration(
                        initial: _lunchBreak,
                        onSelected: (value) {
                          setState(() {
                            _lunchBreak = value;
                          });
                        },
                      ),
                    ),
                    _buildTimeTile(
                      context: context,
                      label: 'Meta diária (legado)',
                      value: _formatDuration(_dailyGoal),
                      onTap: () => _pickDuration(
                        initial: _dailyGoal,
                        onSelected: (value) {
                          setState(() {
                            _dailyGoal = value;
                          });
                        },
                      ),
                    ),
                    _buildTimeTile(
                      context: context,
                      label: 'Horário padrão de entrada (compatibilidade)',
                      value: _defaultEntryTime.format(context),
                      onTap: () => _pickTime(
                        initial: _defaultEntryTime,
                        onSelected: (value) {
                          setState(() {
                            _defaultEntryTime = value;
                          });
                        },
                      ),
                    ),
                    _buildTimeTile(
                      context: context,
                      label: 'Horário padrão de saída (compatibilidade)',
                      value: _defaultExitTime.format(context),
                      onTap: () => _pickTime(
                        initial: _defaultExitTime,
                        onSelected: (value) {
                          setState(() {
                            _defaultExitTime = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Salvar configurações'),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup e segurança',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Use o backup para preservar seus dados antes de atualizar, trocar de celular ou reinstalar o app.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.upload_file_rounded),
                      title: const Text('Exportar backup'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _isBackupBusy ? null : _exportBackup,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.download_rounded),
                      title: const Text('Importar backup'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _isBackupBusy ? null : _importBackup,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value, style: theme.textTheme.bodyMedium),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: _isSaving ? null : onTap,
    );
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required ValueChanged<TimeOfDay> onSelected,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected != null) {
      onSelected(selected);
    }
  }

  Future<void> _pickDuration({
    required Duration initial,
    required ValueChanged<Duration> onSelected,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initial.inHours,
        minute: initial.inMinutes % 60,
      ),
      helpText: 'Selecionar duração',
    );
    if (!mounted) {
      return;
    }
    if (selected != null) {
      final duration = Duration(hours: selected.hour, minutes: selected.minute);
      if (duration.inMinutes <= 0) {
        SnackBarHelper.showWarning(
          context,
          'Escolha uma duração maior que zero.',
        );
        return;
      }
      onSelected(duration);
    }
  }

  Future<void> _save() async {
    final userName = _userNameController.text.trim();

    setState(() {
      _isSaving = true;
    });

    final newSettings = AppSettingsService.current.copyWith(
      userName: userName,
      defaultEntryHour: _effectiveDefaultShift.startHour,
      defaultEntryMinute: _effectiveDefaultShift.startMinute,
      defaultExitHour: _effectiveDefaultShift.endHour,
      defaultExitMinute: _effectiveDefaultShift.endMinute,
      lunchBreakMinutes: _lunchBreak.inMinutes,
      dailyGoalMinutes: _effectiveDefaultShift.duration.inMinutes,
      workDayRule: WorkDayRule(
        defaultShiftType: _defaultShiftType,
        customShift: _customShift.copyWith(type: ShiftType.custom),
        saturdayCompensationEnabled: _saturdayCompensationEnabled,
        saturdayCompensationShift: _saturdayShift.copyWith(type: ShiftType.custom),
        holidays: _holidays,
        companyCalendarRules: _companyRules,
      ),
    );

    try {
      await AppSettingsService.save(newSettings);
      if (!mounted) {
        return;
      }
      widget.onSettingsSaved();
      SnackBarHelper.showSuccess(context, 'Configurações salvas com sucesso!');
    } catch (_) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showError(
        context,
        'Não foi possível salvar as configurações.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isBackupBusy = true;
    });
    try {
      await BackupService.exportBackup();
      if (!mounted) {
        return;
      }
      SnackBarHelper.showSuccess(context, 'Backup exportado com sucesso.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showError(context, 'Não foi possível exportar o backup.');
    } finally {
      if (mounted) {
        setState(() {
          _isBackupBusy = false;
        });
      }
    }
  }

  Future<void> _importBackup() async {
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Importar backup?'),
          content: const Text(
            'A importação pode adicionar ou atualizar registros existentes. Seus dados atuais não serão apagados automaticamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Importar'),
            ),
          ],
        );
      },
    );
    if (shouldImport != true) {
      return;
    }

    setState(() {
      _isBackupBusy = true;
    });
    try {
      await BackupService.importBackupFromFile();
      if (!mounted) {
        return;
      }
      final reloaded = AppSettingsService.current;
      _userNameController.text = reloaded.userName;
      _defaultEntryTime = TimeOfDay(
        hour: reloaded.workDayRule.defaultShift.startHour,
        minute: reloaded.workDayRule.defaultShift.startMinute,
      );
      _defaultExitTime = TimeOfDay(
        hour: reloaded.workDayRule.defaultShift.endHour,
        minute: reloaded.workDayRule.defaultShift.endMinute,
      );
      _lunchBreak = reloaded.lunchBreakDuration;
      _dailyGoal = reloaded.workDayRule.defaultShift.duration;
      _defaultShiftType = reloaded.workDayRule.defaultShiftType;
      _customShift = reloaded.workDayRule.customShift;
      _saturdayCompensationEnabled =
          reloaded.workDayRule.saturdayCompensationEnabled;
      _saturdayShift = reloaded.workDayRule.saturdayCompensationShift;
      _holidays = List<Holiday>.from(reloaded.workDayRule.holidays);
      _companyRules = List<CompanyCalendarRule>.from(
        reloaded.workDayRule.companyCalendarRules,
      );
      setState(() {});
      widget.onSettingsSaved();
      SnackBarHelper.showSuccess(context, 'Backup importado com sucesso.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showError(context, 'Não foi possível importar o backup.');
    } finally {
      if (mounted) {
        setState(() {
          _isBackupBusy = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  WorkShift get _effectiveDefaultShift {
    switch (_defaultShiftType) {
      case ShiftType.firstCommercial:
        return WorkDayRule.defaultFirstCommercialShift;
      case ShiftType.secondCommercial:
        return WorkDayRule.defaultSecondCommercialShift;
      case ShiftType.custom:
        return _customShift.copyWith(type: ShiftType.custom);
    }
  }

  Widget _buildShiftEditor({
    required String title,
    required WorkShift shift,
    required ValueChanged<WorkShift> onUpdate,
  }) {
    return Column(
      children: [
        _buildTimeTile(
          context: context,
          label: '$title - início',
          value: _formatHourMinute(shift.startHour, shift.startMinute),
          onTap: () => _pickTime(
            initial: TimeOfDay(hour: shift.startHour, minute: shift.startMinute),
            onSelected: (value) {
              onUpdate(
                shift.copyWith(startHour: value.hour, startMinute: value.minute),
              );
            },
          ),
        ),
        _buildTimeTile(
          context: context,
          label: '$title - fim',
          value: _formatHourMinute(shift.endHour, shift.endMinute),
          onTap: () => _pickTime(
            initial: TimeOfDay(hour: shift.endHour, minute: shift.endMinute),
            onSelected: (value) {
              onUpdate(shift.copyWith(endHour: value.hour, endMinute: value.minute));
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCalendarRuleChips(ThemeData theme) {
    final widgets = <Widget>[];
    for (final holiday in _holidays) {
      widgets.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Feriado: ${holiday.name}'),
          subtitle: Text(
            '${_formatDate(holiday.date)}${holiday.note == null ? '' : ' • ${holiday.note}'}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              setState(() {
                _holidays.remove(holiday);
              });
            },
          ),
        ),
      );
    }
    for (final rule in _companyRules) {
      widgets.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_workDayTypeLabel(rule.dayType)),
          subtitle: Text(
            '${_formatDate(rule.date)}${rule.note == null ? '' : ' • ${rule.note}'}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              setState(() {
                _companyRules.remove(rule);
              });
            },
          ),
        ),
      );
    }
    if (widgets.isEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Sem regras de calendário cadastradas.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }
    return widgets;
  }

  Future<void> _addHoliday() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date == null || !mounted) {
      return;
    }
    final nameController = TextEditingController();
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo feriado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome do feriado'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Observação'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _holidays = [
          ..._holidays.where((h) => !_sameDate(h.date, date)),
          Holiday(
            date: date,
            name: nameController.text.trim().isEmpty
                ? 'Feriado'
                : nameController.text.trim(),
            note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
          ),
        ];
      });
    }
    nameController.dispose();
    noteController.dispose();
  }

  Future<void> _addCompanyRule(WorkDayType dayType) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date == null || !mounted) {
      return;
    }
    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_workDayTypeLabel(dayType)),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(labelText: 'Observação'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _companyRules = [
          ..._companyRules.where((r) => !_sameDate(r.date, date)),
          CompanyCalendarRule(
            date: date,
            dayType: dayType,
            note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
          ),
        ];
      });
    }
    noteController.dispose();
  }

  String _shiftTypeLabel(ShiftType type) {
    switch (type) {
      case ShiftType.firstCommercial:
        return 'Primeiro comercial (07:00 - 16:48)';
      case ShiftType.secondCommercial:
        return 'Segundo comercial (16:48 - 02:01)';
      case ShiftType.custom:
        return 'Customizado';
    }
  }

  String _workDayTypeLabel(WorkDayType type) {
    switch (type) {
      case WorkDayType.regular:
        return 'Normal';
      case WorkDayType.saturdayCompensation:
        return 'Sábado compensado';
      case WorkDayType.holiday:
        return 'Feriado';
      case WorkDayType.holidayWorkedSwap:
        return 'Troca de feriado';
      case WorkDayType.compensatoryDayOff:
        return 'Folga compensatória';
    }
  }

  String _formatHourMinute(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
