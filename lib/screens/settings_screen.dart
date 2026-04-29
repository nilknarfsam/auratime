import 'package:auratime/core/ui/snackbar_helper.dart';
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
                    Text('Jornada', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildTimeTile(
                      context: context,
                      label: 'Horário padrão de entrada',
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
                      label: 'Horário padrão de saída',
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
                      label: 'Meta diária de jornada',
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
      defaultEntryHour: _defaultEntryTime.hour,
      defaultEntryMinute: _defaultEntryTime.minute,
      defaultExitHour: _defaultExitTime.hour,
      defaultExitMinute: _defaultExitTime.minute,
      lunchBreakMinutes: _lunchBreak.inMinutes,
      dailyGoalMinutes: _dailyGoal.inMinutes,
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
        hour: reloaded.defaultEntryHour,
        minute: reloaded.defaultEntryMinute,
      );
      _defaultExitTime = TimeOfDay(
        hour: reloaded.defaultExitHour,
        minute: reloaded.defaultExitMinute,
      );
      _lunchBreak = reloaded.lunchBreakDuration;
      _dailyGoal = reloaded.dailyGoalDuration;
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
}
