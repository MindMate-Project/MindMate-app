import 'package:equatable/equatable.dart';
import 'package:mindmate/features/caregiver/patients/data/models/caregiver_patient_detail.dart';

sealed class PatientDetailState extends Equatable {
  const PatientDetailState();

  @override
  List<Object?> get props => [];
}

class PatientDetailInitial extends PatientDetailState {
  const PatientDetailInitial();
}

class PatientDetailLoading extends PatientDetailState {
  const PatientDetailLoading();
}

class PatientDetailLoaded extends PatientDetailState {
  final CaregiverPatientDetail patient;

  const PatientDetailLoaded(this.patient);

  @override
  List<Object?> get props => [patient];
}

class PatientDetailError extends PatientDetailState {
  final String message;

  const PatientDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class PatientDetailDeleting extends PatientDetailState {
  final CaregiverPatientDetail patient;

  const PatientDetailDeleting(this.patient);

  @override
  List<Object?> get props => [patient];
}

class PatientDetailAssigningDevice extends PatientDetailState {
  final CaregiverPatientDetail patient;

  const PatientDetailAssigningDevice(this.patient);

  @override
  List<Object?> get props => [patient];
}
