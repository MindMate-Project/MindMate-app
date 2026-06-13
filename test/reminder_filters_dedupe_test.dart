// Tests for medication de-duplication in ReminderFilters.medicationsForDay.
//
// The deployed backend expands one prescription into many occurrence rows
// (one per day x timesPerDay). These tests pin down that the UI collapses
// those rows to one card per dose-time, on both the current per-occurrence
// backend (Tier A) and a hypothetical future single-row backend (Tier B).

import 'package:flutter_test/flutter_test.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/utils/reminder_filters.dart';

ReminderItem _medRow({
  required String id,
  required DateTime scheduled,
  required DateTime start,
  DateTime? end,
  String name = 'panadol',
  String dosage = '1',
  String form = 'tablet',
  String? frequency = 'daily',
  int timesPerDay = 1,
}) =>
    ReminderItem(
      id: id,
      type: 'medication',
      scheduledTime: scheduled,
      isSent: false,
      medicineName: name,
      dosage: dosage,
      form: form,
      frequency: frequency,
      timesPerDay: timesPerDay,
      startDate: start,
      endDate: end,
    );

/// One occurrence row per day, all sharing the same schedule identity.
List<ReminderItem> _dailySeries({
  required String name,
  required DateTime start,
  required int days,
  int hour = 9,
  int minute = 0,
  String idPrefix = 'r',
  String dosage = '1',
  int timesPerDay = 1,
}) {
  final end = DateTime(start.year, start.month, start.day + days - 1);
  return [
    for (var i = 0; i < days; i++)
      _medRow(
        id: '$idPrefix-$i',
        scheduled: DateTime(start.year, start.month, start.day + i, hour, minute),
        start: start,
        end: end,
        name: name,
        dosage: dosage,
        timesPerDay: timesPerDay,
      ),
  ];
}

void main() {
  group('medicationsForDay — de-duplication', () {
    test('30 daily occurrence rows collapse to one card on a mid-range day', () {
      final start = DateTime(2026, 6, 1);
      final items = _dailySeries(name: 'panadol', start: start, days: 30);
      final result = ReminderFilters.medicationsForDay(items, DateTime(2026, 6, 16));

      expect(result.length, 1);
      // Tier A: the card is the real row whose own day is the selected day.
      expect(result.single.id, 'r-15');
    });

    test('twice-daily schedule shows two time-distinct cards, sorted by time', () {
      final start = DateTime(2026, 6, 1);
      // 09:00 rows and 21:00 rows for each day, same schedule identity.
      final morning = _dailySeries(
          name: 'panadol', start: start, days: 30, hour: 9, idPrefix: 'am', timesPerDay: 2);
      final evening = _dailySeries(
          name: 'panadol', start: start, days: 30, hour: 21, idPrefix: 'pm', timesPerDay: 2);
      final result =
          ReminderFilters.medicationsForDay([...morning, ...evening], DateTime(2026, 6, 16));

      expect(result.length, 2);
      expect(result[0].id, 'am-15'); // 09:00 first
      expect(result[1].id, 'pm-15'); // 21:00 second
      expect(result[0].scheduledTime.hour, 9);
      expect(result[1].scheduledTime.hour, 21);
    });

    test('same medicine, different dosage = two distinct cards', () {
      final day = DateTime(2026, 6, 16);
      final items = [
        _medRow(id: 'low', scheduled: DateTime(2026, 6, 16, 9), start: DateTime(2026, 6, 1),
            end: DateTime(2026, 6, 30), dosage: '1'),
        _medRow(id: 'high', scheduled: DateTime(2026, 6, 16, 9), start: DateTime(2026, 6, 1),
            end: DateTime(2026, 6, 30), dosage: '2'),
      ];
      final result = ReminderFilters.medicationsForDay(items, day);
      expect(result.length, 2);
      expect(result.map((r) => r.id).toSet(), {'low', 'high'});
    });

    test('future single-row schedule shows one card on a later day (Tier B)', () {
      // One row standing for a whole daily span — no per-day occurrence rows.
      final items = [
        _medRow(
          id: 'single',
          scheduled: DateTime(2026, 6, 1, 9),
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
      ];
      final result = ReminderFilters.medicationsForDay(items, DateTime(2026, 6, 16));
      expect(result.length, 1);
      expect(result.single.id, 'single');
    });

    test("'once' schedule appears only on its own day", () {
      final items = [
        _medRow(
          id: 'once',
          scheduled: DateTime(2026, 6, 5, 9),
          start: DateTime(2026, 6, 5),
          frequency: 'once',
        ),
      ];
      expect(ReminderFilters.medicationsForDay(items, DateTime(2026, 6, 5)).length, 1);
      expect(ReminderFilters.medicationsForDay(items, DateTime(2026, 6, 6)), isEmpty);
    });

    test('null frequency stays ongoing (legacy/regression guard)', () {
      final items = [
        _medRow(
          id: 'legacy',
          scheduled: DateTime(2026, 4, 5, 9),
          start: DateTime(2026, 4, 5),
          frequency: null,
        ),
      ];
      expect(ReminderFilters.medicationsForDay(items, DateTime(2026, 6, 4)).length, 1);
    });

    test('Tier A picks the selected day even when that day\'s time differs', () {
      final start = DateTime(2026, 6, 1);
      final rows = _dailySeries(name: 'panadol', start: start, days: 10, hour: 9);
      // Replace the day-5 row with one at a different time but same schedule id.
      rows[5] = _medRow(
        id: 'shifted',
        scheduled: DateTime(2026, 6, 6, 10), // day index 5, 10:00 instead of 09:00
        start: start,
        end: DateTime(2026, 6, 10),
      );
      final result = ReminderFilters.medicationsForDay(rows, DateTime(2026, 6, 6));
      expect(result.length, 1);
      expect(result.single.id, 'shifted');
    });
  });
}
