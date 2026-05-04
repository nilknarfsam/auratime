enum WorkDayType {
  regular,
  saturdayCompensation,
  holiday,
  holidayWorkedSwap,
  compensatoryDayOff,
}

enum ShiftType {
  firstCommercial,
  secondCommercial,
  custom,
}

class WorkShift {
  const WorkShift({
    required this.type,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final ShiftType type;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  Duration get duration {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    final delta = end >= start ? end - start : (24 * 60 - start) + end;
    return Duration(minutes: delta);
  }

  bool get isOvernight {
    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;
    return end < start;
  }

  WorkShift copyWith({
    ShiftType? type,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) {
    return WorkShift(
      type: type ?? this.type,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
    };
  }

  static WorkShift fromJson(Map<String, dynamic> json, {required WorkShift fallback}) {
    return WorkShift(
      type: ShiftType.values.firstWhere(
        (item) => item.name == json['type'],
        orElse: () => fallback.type,
      ),
      startHour: (json['startHour'] as num?)?.toInt() ?? fallback.startHour,
      startMinute: (json['startMinute'] as num?)?.toInt() ?? fallback.startMinute,
      endHour: (json['endHour'] as num?)?.toInt() ?? fallback.endHour,
      endMinute: (json['endMinute'] as num?)?.toInt() ?? fallback.endMinute,
    );
  }
}

class Holiday {
  const Holiday({
    required this.date,
    required this.name,
    this.note,
  });

  final DateTime date;
  final String name;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'name': name,
      'note': note,
    };
  }

  static Holiday fromJson(Map<String, dynamic> json) {
    final parsed = DateTime.tryParse((json['date'] as String?) ?? '');
    final date = parsed == null
        ? DateTime.now()
        : DateTime(parsed.year, parsed.month, parsed.day);
    return Holiday(
      date: date,
      name: (json['name'] as String?) ?? 'Feriado',
      note: json['note'] as String?,
    );
  }
}

class CompanyCalendarRule {
  const CompanyCalendarRule({
    required this.date,
    required this.dayType,
    this.note,
  });

  final DateTime date;
  final WorkDayType dayType;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'date': DateTime(date.year, date.month, date.day).toIso8601String(),
      'dayType': dayType.name,
      'note': note,
    };
  }

  static CompanyCalendarRule fromJson(Map<String, dynamic> json) {
    final parsed = DateTime.tryParse((json['date'] as String?) ?? '');
    final date = parsed == null
        ? DateTime.now()
        : DateTime(parsed.year, parsed.month, parsed.day);
    return CompanyCalendarRule(
      date: date,
      dayType: WorkDayType.values.firstWhere(
        (item) => item.name == json['dayType'],
        orElse: () => WorkDayType.regular,
      ),
      note: json['note'] as String?,
    );
  }
}

class WorkDayRule {
  const WorkDayRule({
    required this.defaultShiftType,
    required this.customShift,
    required this.saturdayCompensationEnabled,
    required this.saturdayCompensationShift,
    required this.holidays,
    required this.companyCalendarRules,
  });

  final ShiftType defaultShiftType;
  final WorkShift customShift;
  final bool saturdayCompensationEnabled;
  final WorkShift saturdayCompensationShift;
  final List<Holiday> holidays;
  final List<CompanyCalendarRule> companyCalendarRules;

  factory WorkDayRule.defaults() {
    return WorkDayRule(
      defaultShiftType: ShiftType.firstCommercial,
      customShift: defaultFirstCommercialShift,
      saturdayCompensationEnabled: false,
      saturdayCompensationShift: defaultSaturdayCompensationShift,
      holidays: const [],
      companyCalendarRules: const [],
    );
  }

  static const WorkShift defaultFirstCommercialShift = WorkShift(
    type: ShiftType.firstCommercial,
    startHour: 7,
    startMinute: 0,
    endHour: 16,
    endMinute: 48,
  );

  static const WorkShift defaultSecondCommercialShift = WorkShift(
    type: ShiftType.secondCommercial,
    startHour: 16,
    startMinute: 48,
    endHour: 2,
    endMinute: 1,
  );

  static const WorkShift defaultSaturdayCompensationShift = WorkShift(
    type: ShiftType.custom,
    startHour: 7,
    startMinute: 0,
    endHour: 15,
    endMinute: 0,
  );

  WorkShift get defaultShift {
    switch (defaultShiftType) {
      case ShiftType.firstCommercial:
        return defaultFirstCommercialShift;
      case ShiftType.secondCommercial:
        return defaultSecondCommercialShift;
      case ShiftType.custom:
        return customShift.copyWith(type: ShiftType.custom);
    }
  }

  WorkDayRule copyWith({
    ShiftType? defaultShiftType,
    WorkShift? customShift,
    bool? saturdayCompensationEnabled,
    WorkShift? saturdayCompensationShift,
    List<Holiday>? holidays,
    List<CompanyCalendarRule>? companyCalendarRules,
  }) {
    return WorkDayRule(
      defaultShiftType: defaultShiftType ?? this.defaultShiftType,
      customShift: customShift ?? this.customShift,
      saturdayCompensationEnabled:
          saturdayCompensationEnabled ?? this.saturdayCompensationEnabled,
      saturdayCompensationShift:
          saturdayCompensationShift ?? this.saturdayCompensationShift,
      holidays: holidays ?? this.holidays,
      companyCalendarRules: companyCalendarRules ?? this.companyCalendarRules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'defaultShiftType': defaultShiftType.name,
      'customShift': customShift.toJson(),
      'saturdayCompensationEnabled': saturdayCompensationEnabled,
      'saturdayCompensationShift': saturdayCompensationShift.toJson(),
      'holidays': holidays.map((item) => item.toJson()).toList(),
      'companyCalendarRules': companyCalendarRules.map((item) => item.toJson()).toList(),
    };
  }

  static WorkDayRule fromJson(Map<String, dynamic> json) {
    final defaults = WorkDayRule.defaults();
    return WorkDayRule(
      defaultShiftType: ShiftType.values.firstWhere(
        (item) => item.name == json['defaultShiftType'],
        orElse: () => defaults.defaultShiftType,
      ),
      customShift: WorkShift.fromJson(
        (json['customShift'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
        fallback: defaults.customShift,
      ),
      saturdayCompensationEnabled:
          (json['saturdayCompensationEnabled'] as bool?) ??
              defaults.saturdayCompensationEnabled,
      saturdayCompensationShift: WorkShift.fromJson(
        (json['saturdayCompensationShift'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
        fallback: defaults.saturdayCompensationShift,
      ),
      holidays: (json['holidays'] as List?)
              ?.whereType<Map>()
              .map((item) => Holiday.fromJson(item.cast<String, dynamic>()))
              .toList() ??
          const [],
      companyCalendarRules: (json['companyCalendarRules'] as List?)
              ?.whereType<Map>()
              .map((item) => CompanyCalendarRule.fromJson(item.cast<String, dynamic>()))
              .toList() ??
          const [],
    );
  }
}
