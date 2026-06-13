import 'package:mindmate/features/patient/reminders/data/models/notify_before_options.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';

/// Separates calendar rows from notification-only rows
abstract final class ReminderFilters {
  static bool isAppointment(ReminderItem r) =>
      r.type.toLowerCase() == 'appointment';

  static bool isMedication(ReminderItem r) =>
      r.type.toLowerCase() == 'medication';

  static bool isNotificationOnly(ReminderItem r) {
    if (!isAppointment(r)) return false;
    final notes = r.notes ?? '';
    return notes.contains('(Reminder:');
  }

  /// Rows shown on the Reminders calendar and list.
  static bool isCalendarDisplay(ReminderItem r) => !isNotificationOnly(r);

  static String? notificationOffset(ReminderItem r) {
    final notes = r.notes ?? '';
    if (notes.contains('24h before')) return NotifyBeforeOptions.offset24h;
    if (notes.contains('1h before')) return NotifyBeforeOptions.offset1h;
    return null;
  }

  static DateTime _local(DateTime value) =>
      value.isUtc ? value.toLocal() : value;

  /// Day used for week calendar filtering
  static DateTime calendarDay(ReminderItem r) {
    final instant = _local(r.scheduledTime);
    return DateTime(instant.year, instant.month, instant.day);
  }

  /// Date/time shown on cards and detail
  static DateTime displayDateTime(ReminderItem r) => _local(r.scheduledTime);

  static DateTime _dateOnly(DateTime value) {
    final local = _local(value);
    return DateTime(local.year, local.month, local.day);
  }

  static String _norm(String? s) => (s ?? '').trim().toLowerCase();

  static String _dayKey(DateTime? d) {
    if (d == null) return '';
    final day = _dateOnly(d);
    return '${day.year}-${day.month}-${day.day}';
  }

  /// Local 'HH:mm' of a reminder's scheduled time. Used to keep one card per
  /// dose-time when collapsing a medication's many occurrence rows.
  static String _timeOfDayKey(ReminderItem r) {
    final t = _local(r.scheduledTime);
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Stable identity of one medication *schedule*, independent of which
  /// occurrence row it is. The deployed backend expands a single prescription
  /// into one document per dose (per day x timesPerDay); every such row shares
  /// these fields and differs only in [ReminderItem.scheduledTime]. Time-of-day
  /// is deliberately excluded so a 2x/day med (e.g. 09:00 and 21:00) stays one
  /// series; dosage/form/dates distinguish two different schedules of the same
  /// drug.
  static String medicationSeriesKey(ReminderItem r) => [
        _norm(r.medicineName),
        _norm(r.dosage),
        _norm(r.form),
        _norm(r.frequency),
        r.timesPerDay?.toString() ?? '',
        _dayKey(r.startDate),
        _dayKey(r.endDate),
      ].join('|');

  /// Soonest appointment strictly after [now] (defaults to current time), or
  /// null when there is none. Used for the home "Upcoming Appointment" card.
  static ReminderItem? nextAppointment(
    List<ReminderItem> items, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final upcoming =
        items.where(isAppointment).where(isCalendarDisplay).where((r) => displayDateTime(r).isAfter(ref)).toList()
          ..sort((a, b) => displayDateTime(a).compareTo(displayDateTime(b)));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Medications to display for [day] — one card per distinct dose-time of each
  /// schedule, never one per backend occurrence row.
  ///
  /// A schedule is "active" on [day] when startDate <= day <= endDate (an open
  /// endDate means ongoing); a `frequency == 'once'` schedule is active only on
  /// its own day. Within a schedule we then collapse duplicates:
  ///  - Tier A (current per-occurrence backend): keep the real rows whose own
  ///    calendar day is [day] — exactly one per dose-time, each carrying the
  ///    correct id so tapping a card opens that day's reminder.
  ///  - Tier B (fallback for a future single-row backend, or legacy rows that
  ///    don't materialise an occurrence on [day]): collapse by dose-time,
  ///    keeping the row whose day is closest to [day].
  static List<ReminderItem> medicationsForDay(
    List<ReminderItem> items,
    DateTime day,
  ) {
    final target = DateTime(day.year, day.month, day.day);

    bool activeOn(ReminderItem r) {
      final startDay = _dateOnly(r.startDate ?? r.scheduledTime);
      if (target.isBefore(startDay)) return false;
      if (_norm(r.frequency) == 'once') {
        // One-off schedules occur on a single calendar day only; without this
        // a legacy 'once' row with no endDate would show on every later day.
        return calendarDay(r) == target;
      }
      final end = r.endDate;
      if (end != null && target.isAfter(_dateOnly(end))) return false;
      return true;
    }

    final groups = <String, List<ReminderItem>>{};
    for (final r in items.where(isMedication).where(activeOn)) {
      groups.putIfAbsent(medicationSeriesKey(r), () => <ReminderItem>[]).add(r);
    }

    final result = <ReminderItem>[];
    for (final group in groups.values) {
      final onDay = group.where((r) => calendarDay(r) == target).toList();
      if (onDay.isNotEmpty) {
        result.addAll(onDay);
        continue;
      }
      // Tier B: one entry per dose-time, nearest occurrence wins.
      final byTime = <String, ReminderItem>{};
      for (final r in group) {
        final key = _timeOfDayKey(r);
        final existing = byTime[key];
        if (existing == null ||
            calendarDay(r).difference(target).inDays.abs() <
                calendarDay(existing).difference(target).inDays.abs()) {
          byTime[key] = r;
        }
      }
      result.addAll(byTime.values);
    }

    result.sort((a, b) {
      final byTime = _timeOfDayKey(a).compareTo(_timeOfDayKey(b));
      if (byTime != 0) return byTime;
      return _norm(a.medicineName).compareTo(_norm(b.medicineName));
    });
    return result;
  }

  /// Every medication row belonging to the same schedule as [target] (itself
  /// included). Used to delete a whole prescription, not a single dose, against
  /// the current per-row backend.
  static List<ReminderItem> medicationSiblings(
    List<ReminderItem> items,
    ReminderItem target,
  ) {
    final key = medicationSeriesKey(target);
    return items
        .where(isMedication)
        .where((r) => medicationSeriesKey(r) == key)
        .toList();
  }

  /// The appointment row [target] plus its auto-created advance-notification
  /// rows (24h/1h before). The backend stamps the same `appointmentDate` and
  /// `doctorName` on all three, so they share those fields. Falls back to just
  /// [target] when there is no appointmentDate to match on.
  static List<ReminderItem> appointmentSiblings(
    List<ReminderItem> items,
    ReminderItem target,
  ) {
    final date = target.appointmentDate;
    if (date == null) return [target];
    final doctor = _norm(target.doctorName);
    final day = _dateOnly(date);
    return items.where(isAppointment).where((r) {
      if (_norm(r.doctorName) != doctor) return false;
      final rd = r.appointmentDate;
      return rd != null && _dateOnly(rd) == day;
    }).toList();
  }
}
