import 'dart:async';

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

enum _SaveIndicatorState { idle, saving, saved, error }

class _SettingsScreenState extends State<SettingsScreen> {
  static const double _cardRadius = 16;
  static const EdgeInsets _cardPadding = EdgeInsets.all(14);

  late final TextEditingController _userNameController;
  late TimeOfDay _defaultEntryTime;
  late TimeOfDay _defaultExitTime;
  late Duration _lunchBreak;
  late Duration _dailyGoal;
  late int _cycleStartDay;
  late ShiftType _defaultShiftType;
  late bool _saturdayCompensationEnabled;
  late bool _useBrazilNationalHolidays;
  late bool _useManausAmazonasHolidays;
  late WorkShift _customShift;
  late WorkShift _saturdayShift;
  late List<Holiday> _holidays;
  late List<CompanyCalendarRule> _companyRules;
  Timer? _nameDebounce;
  Timer? _saveStateTimer;
  int _saveGeneration = 0;
  int _latestAppliedGeneration = 0;
  _SaveIndicatorState _saveState = _SaveIndicatorState.idle;
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
    _cycleStartDay = settings.cycleStartDay;
    _defaultShiftType = settings.workDayRule.defaultShiftType;
    _saturdayCompensationEnabled = settings.workDayRule.saturdayCompensationEnabled;
    _useBrazilNationalHolidays = settings.workDayRule.useBrazilNationalHolidays;
    _useManausAmazonasHolidays = settings.workDayRule.useManausAmazonasHolidays;
    _customShift = settings.workDayRule.customShift;
    _saturdayShift = settings.workDayRule.saturdayCompensationShift;
    _holidays = List<Holiday>.from(settings.workDayRule.holidays);
    _companyRules = List<CompanyCalendarRule>.from(
      settings.workDayRule.companyCalendarRules,
    );
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _saveStateTimer?.cancel();
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RepaintBoundary(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Configurações', style: theme.textTheme.headlineMedium),
                  ),
                  _buildSaveIndicator(theme),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Seções organizadas com salvamento automático seguro.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 12),
              _buildProfileSection(theme),
              const SizedBox(height: 10),
              _buildWorkdaySection(theme),
              const SizedBox(height: 10),
              _buildSaturdaySection(theme),
              const SizedBox(height: 10),
              _buildCalendarSection(theme),
              const SizedBox(height: 10),
              _buildCycleSection(theme),
              const SizedBox(height: 10),
              _buildBackupSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveIndicator(ThemeData theme) {
    final (text, icon, color) = switch (_saveState) {
      _SaveIndicatorState.idle => ('', Icons.check_circle_outline_rounded, theme.colorScheme.onSurfaceVariant),
      _SaveIndicatorState.saving => ('Salvando...', Icons.sync_rounded, theme.colorScheme.secondary),
      _SaveIndicatorState.saved => ('Salvo', Icons.check_circle_rounded, const Color(0xFF56F09B)),
      _SaveIndicatorState.error => ('Erro ao salvar', Icons.error_outline_rounded, theme.colorScheme.error),
    };
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  TextStyle? _sectionTitleStyle(ThemeData theme) {
    return theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700);
  }

  TextStyle? _helperStyle(ThemeData theme) {
    return theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
    );
  }

  Widget _sectionCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    String? helper,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_cardRadius)),
      child: Padding(
        padding: _cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: _sectionTitleStyle(theme))),
              ],
            ),
            if (helper != null) ...[
              const SizedBox(height: 6),
              Text(helper, style: _helperStyle(theme)),
            ],
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(ThemeData theme) {
    return _sectionCard(
      theme: theme,
      icon: Icons.person_outline_rounded,
      title: 'Perfil',
      children: [
        TextField(
          controller: _userNameController,
          maxLength: 40,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => _scheduleAutoSave(debounce: true),
          onEditingComplete: () => _scheduleAutoSave(),
          decoration: const InputDecoration(
            labelText: 'Nome do usuário',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkdaySection(ThemeData theme) {
    return _sectionCard(
      theme: theme,
      icon: Icons.work_history_outlined,
      title: 'Jornada de trabalho',
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDefaultShiftBottomSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Turno padrão', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(_shiftTitle(_defaultShiftType), style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          _shiftRange(_defaultShiftType),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 28, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        if (_defaultShiftType == ShiftType.custom) ...[
          const SizedBox(height: 4),
          _buildShiftEditor(
            title: 'Turno customizado',
            shift: _customShift,
            onUpdate: (shift) {
              setState(() => _customShift = shift.copyWith(type: ShiftType.custom));
              _scheduleAutoSave();
            },
          ),
        ],
        _buildTimeTile(
          context: context,
          label: 'Duração do almoço',
          value: _formatDuration(_lunchBreak),
          onTap: () => _pickDuration(
            initial: _lunchBreak,
            onSelected: (value) {
              setState(() => _lunchBreak = value);
              _scheduleAutoSave();
            },
          ),
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          title: Text('Avançado (compatibilidade)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          children: [
            _buildTimeTile(
              context: context,
              label: 'Meta diária (legado)',
              value: _formatDuration(_dailyGoal),
              onTap: () => _pickDuration(
                initial: _dailyGoal,
                onSelected: (value) {
                  setState(() => _dailyGoal = value);
                  _scheduleAutoSave();
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
                  setState(() => _defaultEntryTime = value);
                  _scheduleAutoSave();
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
                  setState(() => _defaultExitTime = value);
                  _scheduleAutoSave();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaturdaySection(ThemeData theme) {
    return _sectionCard(
      theme: theme,
      icon: Icons.event_repeat_rounded,
      title: 'Sábado e compensações',
      helper: 'Sábados e domingos são folga por padrão; use regra do calendário para marcar sábado trabalhado.',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ativar modelo de sábado compensado'),
          value: _saturdayCompensationEnabled,
          onChanged: (value) {
            setState(() => _saturdayCompensationEnabled = value);
            _scheduleAutoSave();
          },
        ),
        if (_saturdayCompensationEnabled)
          _buildShiftEditor(
            title: 'Turno modelo para sábado compensado',
            shift: _saturdayShift,
            onUpdate: (shift) {
              setState(() => _saturdayShift = shift.copyWith(type: ShiftType.custom));
              _scheduleAutoSave();
            },
          ),
      ],
    );
  }

  Widget _buildCalendarSection(ThemeData theme) {
    return _sectionCard(
      theme: theme,
      icon: Icons.calendar_month_outlined,
      title: 'Calendário da empresa',
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Usar feriados nacionais do Brasil'),
          value: _useBrazilNationalHolidays,
          onChanged: (value) {
            setState(() => _useBrazilNationalHolidays = value);
            _scheduleAutoSave();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Usar feriados de Manaus/Amazonas'),
          value: _useManausAmazonasHolidays,
          onChanged: (value) {
            setState(() => _useManausAmazonasHolidays = value);
            _scheduleAutoSave();
          },
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildCalendarRuleButton(label: 'Sábado trabalhado', onPressed: () => _addCompanyRule(WorkDayType.saturdayCompensation)),
            _buildCalendarRuleButton(label: 'Feriado trabalhado por troca', onPressed: () => _addCompanyRule(WorkDayType.holidayWorkedSwap)),
            _buildCalendarRuleButton(label: 'Folga compensatória', onPressed: () => _addCompanyRule(WorkDayType.compensatoryDayOff)),
            _buildCalendarRuleButton(label: 'Feriado', onPressed: () => _addCompanyRule(WorkDayType.holiday)),
            _buildCalendarRuleButton(label: 'Dia normal por exceção', onPressed: () => _addCompanyRule(WorkDayType.regular)),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildCalendarRuleChips(theme),
      ],
    );
  }

  Widget _buildCycleSection(ThemeData theme) {
    return _sectionCard(
      theme: theme,
      icon: Icons.timelapse_rounded,
      title: 'Ciclo mensal',
      helper: 'Use 1 para mês comum ou 16 para ciclo da empresa de 16 a 15.',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Início do ciclo mensal'),
          subtitle: Text(
            'Dia $_cycleStartDay',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _pickCycleStartDay,
        ),
      ],
    );
  }

  Widget _buildBackupSection(ThemeData theme) {
    return _sectionCard(
      theme: theme,
      icon: Icons.shield_outlined,
      title: 'Backup e segurança',
      helper: 'Use o backup para preservar seus dados antes de atualizar, trocar de celular ou reinstalar o app.',
      children: [
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
      subtitle: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildCalendarRuleButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: WidgetStateProperty.all(const Size(0, 34)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            width: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.26),
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return theme.colorScheme.primary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _showDefaultShiftBottomSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      builder: (sheetContext) {
        final maxSheetHeight = MediaQuery.sizeOf(sheetContext).height * 0.55;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 4, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Selecionar turno',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.35,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: colorScheme.outline.withValues(alpha: 0.28),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxSheetHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        for (var i = 0; i < ShiftType.values.length; i++) ...[
                          if (i > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Divider(
                                height: 1,
                                color: colorScheme.outline.withValues(alpha: 0.14),
                              ),
                            ),
                          _buildDefaultShiftSheetTile(sheetContext, theme, ShiftType.values[i]),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultShiftSheetTile(
    BuildContext sheetContext,
    ThemeData theme,
    ShiftType type,
  ) {
    final colorScheme = theme.colorScheme;
    final selected = type == _defaultShiftType;
    final subtleClock = colorScheme.onSurfaceVariant.withValues(
      alpha: selected ? 0.9 : 0.55,
    );
    return Material(
      color: selected ? colorScheme.primary.withValues(alpha: 0.18) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.of(sheetContext).pop();
          if (!mounted) {
            return;
          }
          setState(() => _defaultShiftType = type);
          _scheduleAutoSave();
        },
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 20,
                  color: selected ? colorScheme.primary : subtleClock,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _shiftTitle(type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: selected ? colorScheme.primary : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _shiftRange(type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 26)
                else
                  const SizedBox(width: 26),
              ],
            ),
          ),
        ),
      ),
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

  Future<void> _pickCycleStartDay() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        var tempValue = _cycleStartDay;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Início do ciclo mensal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecione o dia de início do ciclo (1 a 28).',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: tempValue,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Dia do mês',
                    ),
                    items: List.generate(
                      28,
                      (index) => DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text('${index + 1}'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setLocalState(() => tempValue = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(tempValue),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _cycleStartDay = selected.clamp(1, 28);
    });
    _scheduleAutoSave();
  }

  AppSettings _composeCurrentSettings() {
    final userName = _userNameController.text.trim();
    return AppSettingsService.current.copyWith(
      userName: userName,
      defaultEntryHour: _effectiveDefaultShift.startHour,
      defaultEntryMinute: _effectiveDefaultShift.startMinute,
      defaultExitHour: _effectiveDefaultShift.endHour,
      defaultExitMinute: _effectiveDefaultShift.endMinute,
      lunchBreakMinutes: _lunchBreak.inMinutes,
      dailyGoalMinutes: _effectiveDefaultShift.duration.inMinutes,
      cycleStartDay: _cycleStartDay,
      workDayRule: WorkDayRule(
        defaultShiftType: _defaultShiftType,
        customShift: _customShift.copyWith(type: ShiftType.custom),
        saturdayCompensationEnabled: _saturdayCompensationEnabled,
        saturdayCompensationShift: _saturdayShift.copyWith(type: ShiftType.custom),
        useBrazilNationalHolidays: _useBrazilNationalHolidays,
        useManausAmazonasHolidays: _useManausAmazonasHolidays,
        holidays: _holidays,
        companyCalendarRules: _companyRules,
      ),
    );
  }

  void _scheduleAutoSave({bool debounce = false}) {
    _nameDebounce?.cancel();
    if (debounce) {
      _nameDebounce = Timer(const Duration(milliseconds: 550), _persistSettings);
      return;
    }
    unawaited(_persistSettings());
  }

  Future<void> _persistSettings() async {
    final generation = ++_saveGeneration;
    _setSaveState(_SaveIndicatorState.saving);
    final snapshot = _composeCurrentSettings();
    try {
      await AppSettingsService.save(snapshot);
      if (!mounted || generation < _latestAppliedGeneration) {
        return;
      }
      _latestAppliedGeneration = generation;
      widget.onSettingsSaved();
      _setSaveState(_SaveIndicatorState.saved);
    } catch (_) {
      if (!mounted || generation < _latestAppliedGeneration) {
        return;
      }
      _setSaveState(_SaveIndicatorState.error);
    }
  }

  void _setSaveState(_SaveIndicatorState state) {
    if (!mounted) {
      return;
    }
    _saveStateTimer?.cancel();
    setState(() {
      _saveState = state;
    });
    if (state == _SaveIndicatorState.saved || state == _SaveIndicatorState.error) {
      _saveStateTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) {
          return;
        }
        setState(() => _saveState = _SaveIndicatorState.idle);
      });
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
      _cycleStartDay = reloaded.cycleStartDay;
      _defaultShiftType = reloaded.workDayRule.defaultShiftType;
      _customShift = reloaded.workDayRule.customShift;
      _saturdayCompensationEnabled =
          reloaded.workDayRule.saturdayCompensationEnabled;
      _useBrazilNationalHolidays = reloaded.workDayRule.useBrazilNationalHolidays;
      _useManausAmazonasHolidays = reloaded.workDayRule.useManausAmazonasHolidays;
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
              _scheduleAutoSave();
            },
          ),
        ),
      );
    }
    for (final rule in _companyRules) {
      widgets.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(_calendarRuleOptionLabel(rule.dayType)),
          subtitle: Text(
            '${_formatDate(rule.date)}${rule.note == null ? '' : ' • ${rule.note}'}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              setState(() {
                _companyRules.remove(rule);
              });
              _scheduleAutoSave();
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
        title: Text(_calendarRuleOptionLabel(dayType)),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Observação (decisão da empresa)',
          ),
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
      _scheduleAutoSave();
    }
    noteController.dispose();
  }

  String _shiftTitle(ShiftType type) {
    switch (type) {
      case ShiftType.firstCommercial:
        return 'Primeiro comercial';
      case ShiftType.secondCommercial:
        return 'Segundo comercial';
      case ShiftType.custom:
        return 'Customizado';
    }
  }

  String _shiftRange(ShiftType type) {
    switch (type) {
      case ShiftType.firstCommercial:
        return '07:00 → 16:48';
      case ShiftType.secondCommercial:
        return '16:48 → 02:01';
      case ShiftType.custom:
        return '${_formatHourMinute(_customShift.startHour, _customShift.startMinute)} → ${_formatHourMinute(_customShift.endHour, _customShift.endMinute)}';
    }
  }

  String _calendarRuleOptionLabel(WorkDayType type) {
    switch (type) {
      case WorkDayType.regular:
        return 'Dia normal por exceção';
      case WorkDayType.saturdayCompensation:
        return 'Sábado trabalhado';
      case WorkDayType.holiday:
        return 'Feriado';
      case WorkDayType.holidayWorkedSwap:
        return 'Feriado trabalhado por troca';
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
