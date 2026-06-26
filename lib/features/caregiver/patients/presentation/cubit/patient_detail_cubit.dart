import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/caregiver/patients/data/services/device_service.dart';
import 'patient_detail_state.dart';

class PatientDetailCubit extends Cubit<PatientDetailState> {
  PatientDetailCubit(
    this._service,
    this._deviceService,
    this.patientId,
  ) : super(const PatientDetailInitial());

  final AssignmentService _service;
  final DeviceService _deviceService;
  final String patientId;

  Future<void> load() async {
    emit(const PatientDetailLoading());
    try {
      final patient = await _service.fetchPatientDetail(patientId);
      emit(PatientDetailLoaded(patient));
    } catch (e) {
      emit(
        PatientDetailError(e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }

  Future<bool> deletePatient() async {
    final current = state;
    if (current is! PatientDetailLoaded) return false;

    emit(PatientDetailDeleting(current.patient));
    try {
      await _service.removePatient(patientId);
      return true;
    } catch (e) {
      emit(PatientDetailLoaded(current.patient));
      rethrow;
    }
  }

  Future<void> removeDevice() async {
    final current = state;
    if (current is! PatientDetailLoaded) return;

    emit(PatientDetailAssigningDevice(current.patient));
    try {
      await _deviceService.removeDevice(patientId);
      await load();
    } catch (e) {
      emit(PatientDetailLoaded(current.patient));
      rethrow;
    }
  }

  Future<void> assignDevice(String deviceId) async {
    final current = state;
    if (current is! PatientDetailLoaded) return;

    final email = current.patient.email?.trim() ?? '';
    if (email.isEmpty) {
      throw Exception('Patient email is unavailable for device assignment.');
    }

    emit(PatientDetailAssigningDevice(current.patient));
    try {
      await _deviceService.assignDevice(
        deviceId: deviceId,
        patientEmail: email,
      );
      await load();
    } catch (e) {
      emit(PatientDetailLoaded(current.patient));
      rethrow;
    }
  }
}
