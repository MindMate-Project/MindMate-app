import 'package:equatable/equatable.dart';
import 'package:mindmate/features/caregiver/patients/data/models/caregiver_patient_detail.dart';

sealed class EditPatientState extends Equatable {
  const EditPatientState();

  @override
  List<Object?> get props => [];
}

class EditPatientInitial extends EditPatientState {
  const EditPatientInitial();
}

class EditPatientSaving extends EditPatientState {
  const EditPatientSaving();
}

class EditPatientSuccess extends EditPatientState {
  final CaregiverPatientDetail patient;

  const EditPatientSuccess(this.patient);

  @override
  List<Object?> get props => [patient];
}

class EditPatientError extends EditPatientState {
  final String message;

  const EditPatientError(this.message);

  @override
  List<Object?> get props => [message];
}
