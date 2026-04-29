class BackupPayload {
  const BackupPayload({
    required this.backupVersion,
    required this.appName,
    required this.createdAt,
    required this.appVersion,
    required this.settings,
    required this.records,
  });

  final int backupVersion;
  final String appName;
  final String createdAt;
  final String appVersion;
  final BackupSettings settings;
  final List<BackupRecord> records;

  Map<String, dynamic> toJson() {
    return {
      'backupVersion': backupVersion,
      'appName': appName,
      'createdAt': createdAt,
      'appVersion': appVersion,
      'settings': settings.toJson(),
      'records': records.map((item) => item.toJson()).toList(),
    };
  }

  static BackupPayload fromJson(Map<String, dynamic> json) {
    final rawSettings = json['settings'];
    final rawRecords = json['records'];
    return BackupPayload(
      backupVersion: (json['backupVersion'] as num?)?.toInt() ?? 1,
      appName: (json['appName'] as String?) ?? '',
      createdAt: (json['createdAt'] as String?) ?? '',
      appVersion: (json['appVersion'] as String?) ?? '',
      settings: BackupSettings.fromJson(
        (rawSettings is Map<String, dynamic>)
            ? rawSettings
            : <String, dynamic>{},
      ),
      records: rawRecords is List
          ? rawRecords
                .whereType<Map>()
                .map(
                  (item) => BackupRecord.fromJson(item.cast<String, dynamic>()),
                )
                .toList()
          : const [],
    );
  }
}

class BackupSettings {
  const BackupSettings({
    required this.userName,
    required this.defaultEntryHour,
    required this.defaultEntryMinute,
    required this.defaultExitHour,
    required this.defaultExitMinute,
    required this.lunchBreakMinutes,
    required this.dailyGoalMinutes,
  });

  final String userName;
  final int defaultEntryHour;
  final int defaultEntryMinute;
  final int defaultExitHour;
  final int defaultExitMinute;
  final int lunchBreakMinutes;
  final int dailyGoalMinutes;

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'defaultEntryHour': defaultEntryHour,
      'defaultEntryMinute': defaultEntryMinute,
      'defaultExitHour': defaultExitHour,
      'defaultExitMinute': defaultExitMinute,
      'lunchBreakMinutes': lunchBreakMinutes,
      'dailyGoalMinutes': dailyGoalMinutes,
    };
  }

  static BackupSettings fromJson(Map<String, dynamic> json) {
    return BackupSettings(
      userName: (json['userName'] as String?) ?? '',
      defaultEntryHour: (json['defaultEntryHour'] as num?)?.toInt() ?? 7,
      defaultEntryMinute: (json['defaultEntryMinute'] as num?)?.toInt() ?? 0,
      defaultExitHour: (json['defaultExitHour'] as num?)?.toInt() ?? 16,
      defaultExitMinute: (json['defaultExitMinute'] as num?)?.toInt() ?? 48,
      lunchBreakMinutes: (json['lunchBreakMinutes'] as num?)?.toInt() ?? 60,
      dailyGoalMinutes: (json['dailyGoalMinutes'] as num?)?.toInt() ?? 528,
    );
  }
}

class BackupRecord {
  const BackupRecord({
    required this.date,
    required this.entryTime,
    required this.exitTime,
    required this.dayType,
    required this.note,
  });

  final String date;
  final String? entryTime;
  final String? exitTime;
  final String dayType;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'entryTime': entryTime,
      'exitTime': exitTime,
      'dayType': dayType,
      'note': note,
    };
  }

  static BackupRecord fromJson(Map<String, dynamic> json) {
    return BackupRecord(
      date: (json['date'] as String?) ?? '',
      entryTime: json['entryTime'] as String?,
      exitTime: json['exitTime'] as String?,
      dayType: (json['dayType'] as String?) ?? 'regular',
      note: json['note'] as String?,
    );
  }
}
