// Tests for sibling resolution used by "delete the whole schedule".
// Pure logic over ReminderFilters — no network.

import 'package:flutter_test/flutter_test.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/utils/reminder_filters.dart';

ReminderItem _med(String id, {String name = 'panadol', String dosage = '1'}) =>
    ReminderItem(
      id: id,
      type: 'medication',
      scheduledTime: DateTime(2026, 6, 1, 9),
      isSent: false,
      medicineName: name,
      dosage: dosage,
      form: 'tablet',
      frequency: 'daily',
      timesPerDay: 1,
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
    );

ReminderItem _appt(
  String id, {
  required DateTime apptDate,
  required DateTime scheduled,
  String doctor = 'Dr. A',
  String? notes,
}) =>
    ReminderItem(
      id: id,
      type: 'appointment',
      scheduledTime: scheduled,
      isSent: false,
      doctorName: doctor,
      appointmentDate: apptDate,
      notes: notes,
    );

void main() {
  group('medicationSiblings', () {
    test('returns every row of the schedule, excluding others', () {
      final series = [for (var i = 0; i < 30; i++) _med('panadol-$i')];
      final items = [
        ...series,
        _med('other', name: 'paracetamol'), // different medicine
        _appt('appt', apptDate: DateTime(2026, 6, 10), scheduled: DateTime(2026, 6, 10, 15)),
      ];
      final siblings = ReminderFilters.medicationSiblings(items, series.first);
      expect(siblings.length, 30);
      expect(siblings.every((r) => r.medicineName == 'panadol'), isTrue);
    });

    test('different dosage of same medicine is NOT a sibling', () {
      final a = _med('a', dosage: '1');
      final b = _med('b', dosage: '2');
      expect(ReminderFilters.medicationSiblings([a, b], a).map((r) => r.id), ['a']);
    });
  });

  group('appointmentSiblings', () {
    test('returns main + 24h + 1h rows sharing doctor and date', () {
      final apptDate = DateTime(2026, 6, 13);
      final main = _appt('main', apptDate: apptDate, scheduled: DateTime(2026, 6, 13, 15));
      final h24 = _appt('h24',
          apptDate: apptDate,
          scheduled: DateTime(2026, 6, 12, 15),
          notes: '(Reminder: 24h before)');
      final h1 = _appt('h1',
          apptDate: apptDate,
          scheduled: DateTime(2026, 6, 13, 14),
          notes: '(Reminder: 1h before)');
      final otherDate =
          _appt('other', apptDate: DateTime(2026, 6, 20), scheduled: DateTime(2026, 6, 20, 15));

      final siblings = ReminderFilters.appointmentSiblings([main, h24, h1, otherDate], main);
      expect(siblings.map((r) => r.id).toSet(), {'main', 'h24', 'h1'});
    });

    test('falls back to just the target when appointmentDate is null', () {
      final main = ReminderItem(
        id: 'main',
        type: 'appointment',
        scheduledTime: DateTime(2026, 6, 13, 15),
        isSent: false,
        doctorName: 'Dr. A',
      );
      final siblings = ReminderFilters.appointmentSiblings([main], main);
      expect(siblings.map((r) => r.id), ['main']);
    });
  });
}
