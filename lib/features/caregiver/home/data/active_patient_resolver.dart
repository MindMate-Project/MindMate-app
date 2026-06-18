import 'package:mindmate/core/network/patient_context_store.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/caregiver/home/presentation/models/active_patient.dart';

/// Resolves the caregiver's currently selected patient from local storage + API.
class ActivePatientResolver {
  ActivePatientResolver({
    AssignmentService? assignments,
    PatientContextStore? store,
  })  : _assignments = assignments ?? AssignmentService(),
        _store = store ?? PatientContextStore();

  final AssignmentService _assignments;
  final PatientContextStore _store;

  Future<ActivePatient?> resolve() async {
    final id = await _store.getActivePatientId();
    if (id == null || id.isEmpty) return null;

    try {
      final patients = await _assignments.fetchCaregiverPatients();
      for (final row in patients) {
        if (row.patientId == id) return ActivePatient.fromRow(row);
      }
    } catch (_) {}

    return ActivePatient(id: id, name: 'Patient');
  }
}
