// Unit tests for ReminderFilters — the pure date logic behind the home
// "Today's Medicine" card and the Reminders calendar's Medication tab.
//
// (Replaces the default counter smoke test, which was commented out and made
// `flutter test` fail to load with "Missing definition of `main`".)

import 'package:flutter_test/flutter_test.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/utils/reminder_filters.dart';

ReminderItem _med({
  required String name,
  DateTime? start,
  DateTime? end,
  int hour = 9,
}) =>
    ReminderItem(
      id: name,
      type: 'medication',
      scheduledTime: start ?? DateTime(2026, 1, 1, hour),
      isSent: false,
      medicineName: name,
      startDate: start,
      endDate: end,
    );

ReminderItem _appt(DateTime when) => ReminderItem(
      id: 'appt-${when.toIso8601String()}',
      type: 'appointment',
      scheduledTime: when,
      isSent: false,
      doctorName: 'Dr. Test',
    );

void main() {
  group('ReminderFilters.medicationsForDay', () {
    test('includes an ongoing daily med on a day after its start date', () {
      final items = [_med(name: 'paracetamol', start: DateTime(2026, 4, 5))];
      final result =
          ReminderFilters.medicationsForDay(items, DateTime(2026, 6, 4));
      expect(result.map((m) => m.medicineName), ['paracetamol']);
    });

    test('excludes a med before its start date', () {
      final items = [_med(name: 'panadol', start: DateTime(2026, 6, 10))];
      expect(
        ReminderFilters.medicationsForDay(items, DateTime(2026, 6, 4)),
        isEmpty,
      );
    });

    test('excludes a med after its end date', () {
      final items = [
        _med(name: 'panadol', start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 3)),
      ];
      expect(
        ReminderFilters.medicationsForDay(items, DateTime(2026, 6, 4)),
        isEmpty,
      );
    });

    test('includes a med on its end date (inclusive)', () {
      final items = [
        _med(name: 'panadol', start: DateTime(2026, 6, 1), end: DateTime(2026, 6, 4)),
      ];
      expect(
        ReminderFilters.medicationsForDay(items, DateTime(2026, 6, 4)).length,
        1,
      );
    });

    test('ignores appointments', () {
      final items = [_appt(DateTime(2026, 6, 4, 15))];
      expect(
        ReminderFilters.medicationsForDay(items, DateTime(2026, 6, 4)),
        isEmpty,
      );
    });
  });

  group('ReminderFilters.nextAppointment', () {
    test('returns the soonest appointment strictly after now', () {
      final items = [
        _appt(DateTime(2026, 6, 1, 10)),
        _appt(DateTime(2026, 6, 27, 15)),
        _appt(DateTime(2026, 6, 10, 9)),
      ];
      final next = ReminderFilters.nextAppointment(
        items,
        now: DateTime(2026, 6, 4),
      );
      expect(next, isNotNull);
      expect(next!.scheduledTime, DateTime(2026, 6, 10, 9));
    });

    test('returns null when there is no upcoming appointment', () {
      final items = [_appt(DateTime(2026, 1, 1, 10))];
      expect(
        ReminderFilters.nextAppointment(items, now: DateTime(2026, 6, 4)),
        isNull,
      );
    });
  });
}
