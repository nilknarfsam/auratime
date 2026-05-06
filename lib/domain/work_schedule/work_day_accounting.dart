/// Canonical gross vs net work accounting: shift [duration] is on-site span;
/// [lunchBreak] is deducted once to get contractual worked time.
class WorkDayAccounting {
  const WorkDayAccounting._();

  /// Net time the employee must work to fulfill the shift (gross span minus lunch).
  static Duration expectedNetWork({
    required Duration grossShiftDuration,
    required Duration lunchBreak,
  }) {
    final net = grossShiftDuration - lunchBreak;
    return net <= Duration.zero ? Duration.zero : net;
  }

  /// Net worked time from punches. Matches [TimeRecord.totalWorkedHours] when [exit] is set.
  static Duration workedNetSession({
    required DateTime? entry,
    required DateTime? exit,
    required DateTime now,
    required Duration lunchBreak,
  }) {
    if (entry == null) {
      return Duration.zero;
    }
    final end = exit ?? now;
    var gross = end.difference(entry);
    if (gross <= Duration.zero) {
      return Duration.zero;
    }
    if (exit != null) {
      if (gross <= lunchBreak) {
        return Duration.zero;
      }
      return gross - lunchBreak;
    }
    if (gross <= lunchBreak) {
      return gross;
    }
    return gross - lunchBreak;
  }

  static double progress01({
    required Duration workedNet,
    required Duration expectedNet,
  }) {
    if (expectedNet.inMinutes <= 0) {
      return 0;
    }
    return (workedNet.inMinutes / expectedNet.inMinutes).clamp(0.0, 1.0);
  }
}
