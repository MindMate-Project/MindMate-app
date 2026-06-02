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

  /// Soonest appointment strictly after [now] (defaults to current time), or
  /// null when there is none. Used for the home "Upcoming Appointment" card.
  static ReminderItem? nextAppointment(
    List<ReminderItem> items, {
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final upcoming =
        items.where(isAppointment).where((r) => displayDateTime(r).isAfter(ref)).toList()
          ..sort((a, b) => displayDateTime(a).compareTo(displayDateTime(b)));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  /// Medications active on [day] — i.e. startDate <= day <= endDate (an open
  /// endDate means ongoing). Used for the home "Today's Medicine" card.
  static List<ReminderItem> medicationsForDay(
    List<ReminderItem> items,
    DateTime day,
  ) {
    final target = DateTime(day.year, day.month, day.day);
    bool activeOn(ReminderItem r) {
      final startDay = _dateOnly(r.startDate ?? r.scheduledTime);
      if (target.isBefore(startDay)) return false;
      final end = r.endDate;
      if (end != null && target.isAfter(_dateOnly(end))) return false;
      return true;
    }

    return items.where(isMedication).where(activeOn).toList()
      ..sort((a, b) => displayDateTime(a).compareTo(displayDateTime(b)));
  }
}
