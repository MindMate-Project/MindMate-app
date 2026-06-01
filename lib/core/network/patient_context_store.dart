import 'package:shared_preferences/shared_preferences.dart';

/// Stores the currently active patient id used by caregiver-dependent features.
class PatientContextStore {
  static const String _patientIdKey = 'patient_id';

  Future<String?> getActivePatientId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_patientIdKey);
    if (id == null || id.trim().isEmpty) return null;
    return id;
  }

  Future<void> setActivePatientId(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patientIdKey, patientId.trim());
  }

  Future<void> clearActivePatientId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_patientIdKey);
  }
}
