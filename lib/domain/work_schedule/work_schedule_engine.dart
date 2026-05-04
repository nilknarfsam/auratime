import 'package:auratime/domain/work_schedule/work_schedule_models.dart';

class WorkScheduleEngine {
  const WorkScheduleEngine(this.rule);

  final WorkDayRule rule;

  WorkDayType getDayType(DateTime date) {
    final normalized = _normalizeDate(date);
    final override = _companyRuleFor(normalized);
    if (override != null) {
      return override.dayType;
    }
    if (isHoliday(normalized)) {
      return WorkDayType.holiday;
    }
    if (normalized.weekday == DateTime.saturday && rule.saturdayCompensationEnabled) {
      return WorkDayType.saturdayCompensation;
    }
    return WorkDayType.regular;
  }

  WorkShift? getShiftForDate(DateTime date) {
    final dayType = getDayType(date);
    switch (dayType) {
      case WorkDayType.regular:
      case WorkDayType.holidayWorkedSwap:
        return rule.defaultShift;
      case WorkDayType.saturdayCompensation:
        return rule.saturdayCompensationShift;
      case WorkDayType.holiday:
      case WorkDayType.compensatoryDayOff:
        return null;
    }
  }

  Duration calculateExpectedDuration(DateTime date) {
    return getShiftForDate(date)?.duration ?? Duration.zero;
  }

  DateTime? calculateExpectedExit(DateTime date, DateTime checkIn) {
    final shift = getShiftForDate(date);
    if (shift == null) {
      return null;
    }
    return checkIn.add(shift.duration);
  }

  bool isHoliday(DateTime date) {
    final normalized = _normalizeDate(date);
    return rule.holidays.any((holiday) => _sameDate(holiday.date, normalized));
  }

  bool isWorkingDay(DateTime date) {
    final expected = calculateExpectedDuration(date);
    return expected > Duration.zero;
  }

  CompanyCalendarRule? _companyRuleFor(DateTime date) {
    for (final item in rule.companyCalendarRules) {
      if (_sameDate(item.date, date)) {
        return item;
      }
    }
    return null;
  }

  DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
