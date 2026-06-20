import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'patient_caregiver_detail_state.dart';

class PatientCaregiverDetailCubit extends Cubit<PatientCaregiverDetailState> {
  PatientCaregiverDetailCubit(
    this._service, {
    required this.caregiverId,
    required this.patientId,
  }) : super(const PatientCaregiverDetailInitial());

  final AssignmentService _service;
  final String caregiverId;
  final String patientId;

  Future<void> load() async {
    emit(const PatientCaregiverDetailLoading());
    try {
      final caregiver = await _service.fetchCaregiverDetail(
        caregiverId,
        patientId: patientId,
      );
      emit(PatientCaregiverDetailLoaded(caregiver));
    } catch (e) {
      emit(
        PatientCaregiverDetailError(
          e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<bool> removeCaregiver() async {
    final current = state;
    if (current is! PatientCaregiverDetailLoaded) return false;

    emit(PatientCaregiverDetailDeleting(current.caregiver));
    try {
      await _service.removeCaregiverFromPatient(caregiverId);
      return true;
    } catch (e) {
      emit(PatientCaregiverDetailLoaded(current.caregiver));
      rethrow;
    }
  }
}
