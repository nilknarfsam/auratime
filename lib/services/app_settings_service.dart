import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({
    required this.userName,
    required this.defaultEntryHour,
    required this.defaultEntryMinute,
    required this.defaultExitHour,
    required this.defaultExitMinute,
    required this.lunchBreakMinutes,
    required this.dailyGoalMinutes,
  });

  factory AppSettings.defaults() {
    return const AppSettings(
      userName: 'Usuário',
      defaultEntryHour: 7,
      defaultEntryMinute: 0,
      defaultExitHour: 16,
      defaultExitMinute: 48,
      lunchBreakMinutes: 60,
      dailyGoalMinutes: 528,
    );
  }

  final String userName;
  final int defaultEntryHour;
  final int defaultEntryMinute;
  final int defaultExitHour;
  final int defaultExitMinute;
  final int lunchBreakMinutes;
  final int dailyGoalMinutes;

  Duration get lunchBreakDuration => Duration(minutes: lunchBreakMinutes);
  Duration get dailyGoalDuration => Duration(minutes: dailyGoalMinutes);

  AppSettings copyWith({
    String? userName,
    int? defaultEntryHour,
    int? defaultEntryMinute,
    int? defaultExitHour,
    int? defaultExitMinute,
    int? lunchBreakMinutes,
    int? dailyGoalMinutes,
  }) {
    return AppSettings(
      userName: userName ?? this.userName,
      defaultEntryHour: defaultEntryHour ?? this.defaultEntryHour,
      defaultEntryMinute: defaultEntryMinute ?? this.defaultEntryMinute,
      defaultExitHour: defaultExitHour ?? this.defaultExitHour,
      defaultExitMinute: defaultExitMinute ?? this.defaultExitMinute,
      lunchBreakMinutes: lunchBreakMinutes ?? this.lunchBreakMinutes,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }
}

class AppSettingsService {
  static const _userNameKey = 'settings_user_name';
  static const _defaultEntryHourKey = 'settings_default_entry_hour';
  static const _defaultEntryMinuteKey = 'settings_default_entry_minute';
  static const _defaultExitHourKey = 'settings_default_exit_hour';
  static const _defaultExitMinuteKey = 'settings_default_exit_minute';
  static const _lunchBreakMinutesKey = 'settings_lunch_break_minutes';
  static const _dailyGoalMinutesKey = 'settings_daily_goal_minutes';

  static AppSettings _current = AppSettings.defaults();
  static final ValueNotifier<AppSettings> settingsListenable =
      ValueNotifier<AppSettings>(_current);

  static AppSettings get current => _current;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _current = AppSettings(
      userName: prefs.getString(_userNameKey) ?? AppSettings.defaults().userName,
      defaultEntryHour:
          prefs.getInt(_defaultEntryHourKey) ?? AppSettings.defaults().defaultEntryHour,
      defaultEntryMinute: prefs.getInt(_defaultEntryMinuteKey) ??
          AppSettings.defaults().defaultEntryMinute,
      defaultExitHour:
          prefs.getInt(_defaultExitHourKey) ?? AppSettings.defaults().defaultExitHour,
      defaultExitMinute:
          prefs.getInt(_defaultExitMinuteKey) ?? AppSettings.defaults().defaultExitMinute,
      lunchBreakMinutes:
          prefs.getInt(_lunchBreakMinutesKey) ?? AppSettings.defaults().lunchBreakMinutes,
      dailyGoalMinutes:
          prefs.getInt(_dailyGoalMinutesKey) ?? AppSettings.defaults().dailyGoalMinutes,
    );
    settingsListenable.value = _current;
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, settings.userName.trim());
    await prefs.setInt(_defaultEntryHourKey, settings.defaultEntryHour);
    await prefs.setInt(_defaultEntryMinuteKey, settings.defaultEntryMinute);
    await prefs.setInt(_defaultExitHourKey, settings.defaultExitHour);
    await prefs.setInt(_defaultExitMinuteKey, settings.defaultExitMinute);
    await prefs.setInt(_lunchBreakMinutesKey, settings.lunchBreakMinutes);
    await prefs.setInt(_dailyGoalMinutesKey, settings.dailyGoalMinutes);
    _current = settings.copyWith(userName: settings.userName.trim());
    settingsListenable.value = _current;
  }
}
