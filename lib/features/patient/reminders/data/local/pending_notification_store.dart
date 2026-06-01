import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Medication notify prefs 
class PendingMedicationNotification {
  const PendingMedicationNotification({
    required this.patientId,
    required this.medicineName,
    required this.startDateIso,
    required this.endDateIso,
    required this.timeHour,
    required this.timeMinute,
    required this.frequency,
    required this.offsets,
  });

  final String patientId;
  final String medicineName;
  final String startDateIso;
  final String endDateIso;
  final int timeHour;
  final int timeMinute;
  final String frequency;
  final List<String> offsets;

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'medicineName': medicineName,
        'startDateIso': startDateIso,
        'endDateIso': endDateIso,
        'timeHour': timeHour,
        'timeMinute': timeMinute,
        'frequency': frequency,
        'offsets': offsets,
      };

  factory PendingMedicationNotification.fromJson(Map<String, dynamic> json) {
    return PendingMedicationNotification(
      patientId: json['patientId'] as String,
      medicineName: json['medicineName'] as String,
      startDateIso: json['startDateIso'] as String,
      endDateIso: json['endDateIso'] as String,
      timeHour: json['timeHour'] as int,
      timeMinute: json['timeMinute'] as int,
      frequency: json['frequency'] as String,
      offsets: List<String>.from(json['offsets'] as List),
    );
  }
}

/// Local queue for medication lead-time alerts 
class PendingNotificationStore {
  static const _key = 'pending_medication_notifications';

  Future<void> addMedication(PendingMedicationNotification entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _readAll(prefs);
    list.add(entry);
    await prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<List<PendingMedicationNotification>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _readAll(prefs);
  }

  Future<List<PendingMedicationNotification>> _readAll(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => PendingMedicationNotification.fromJson(
              e as Map<String, dynamic>,
            ))
        .toList();
  }
}
