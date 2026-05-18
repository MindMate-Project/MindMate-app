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
}
