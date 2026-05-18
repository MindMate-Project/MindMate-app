import 'package:flutter/material.dart';

/// Maps UI form values to API for `/api/reminders`.
abstract final class ReminderApiMapper {
  static DateTime mergeDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Full instant for `scheduledTime`
  static String toInstantIso(DateTime value) => value.toUtc().toIso8601String();

  /// Calendar date only
  static String toDateIso(DateTime date) {
    final d = dateOnly(date);
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @Deprecated('Use toInstantIso or toDateIso')
  static String toIso(DateTime value) => toInstantIso(value);

  static String appointmentTypeFromUi(String label) {
    switch (label.toLowerCase().replaceAll(' ', '')) {
      case 'consultation':
        return 'consultation';
      case 'follow-up':
      case 'followup':
        return 'follow-up';
      case 'lab':
        return 'lab';
      case 'scan':
        return 'scan';
      default:
        return label.toLowerCase();
    }
  }

  /// Maps API `appointmentType` to UI radio labels.
  static String? appointmentTypeToUi(String? api) {
    if (api == null || api.trim().isEmpty) return null;
    switch (api.trim().toLowerCase()) {
      case 'consultation':
        return 'Consultation';
      case 'follow-up':
      case 'followup':
        return 'Follow-Up';
      case 'lab':
        return 'Lab';
      case 'scan':
        return 'Scan';
      default:
        final s = api.trim();
        return s.isEmpty ? null : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
    }
  }

  static String medicationFormFromUi(String label) => label.toLowerCase();

  static String? medicationFormToUi(String? api) {
    if (api == null || api.trim().isEmpty) return null;
    switch (api.trim().toLowerCase()) {
      case 'tablet':
        return 'Tablet';
      case 'capsule':
        return 'Capsule';
      case 'syrup':
        return 'Syrup';
      case 'injection':
        return 'Injection';
      default:
        final s = api.trim();
        return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
    }
  }

  static String frequencyFromUi(String label) => label.toLowerCase();

  static String? frequencyToUi(String? api) {
    if (api == null || api.trim().isEmpty) return null;
    switch (api.trim().toLowerCase()) {
      case 'once':
        return 'Once';
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      default:
        final s = api.trim();
        return '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
    }
  }

  static int parseTimesPerDay(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 1;
    final n = int.tryParse(raw.trim());
    if (n == null || n < 1) return 1;
    return n;
  }
}
