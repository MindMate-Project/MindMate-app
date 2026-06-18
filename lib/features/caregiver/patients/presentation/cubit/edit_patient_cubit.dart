import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/caregiver/patients/data/models/caregiver_patient_detail.dart';
import 'edit_patient_state.dart';

class EditPatientCubit extends Cubit<EditPatientState> {
  EditPatientCubit(this._service, this.patientId)
      : super(const EditPatientInitial());

  final AssignmentService _service;
  final String patientId;

  Future<void> save({
    required String name,
    DateTime? dateOfBirth,
    required PatientMedicalNotes medicalNotes,
  }) async {
    emit(const EditPatientSaving());
    try {
      final patient = await _service.updatePatient(
        patientId: patientId,
        name: name,
        dateOfBirth: dateOfBirth,
        medicalNotes: medicalNotes,
      );
      emit(EditPatientSuccess(patient));
    } catch (e) {
      emit(EditPatientError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
