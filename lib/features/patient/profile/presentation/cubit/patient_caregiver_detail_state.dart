import 'package:equatable/equatable.dart';
import 'package:mindmate/features/assignments/data/models/connected_caregiver.dart';

sealed class PatientCaregiverDetailState extends Equatable {
  const PatientCaregiverDetailState();

  @override
  List<Object?> get props => [];
}

final class PatientCaregiverDetailInitial extends PatientCaregiverDetailState {
  const PatientCaregiverDetailInitial();
}

final class PatientCaregiverDetailLoading extends PatientCaregiverDetailState {
  const PatientCaregiverDetailLoading();
}

final class PatientCaregiverDetailLoaded extends PatientCaregiverDetailState {
  final ConnectedCaregiver caregiver;

  const PatientCaregiverDetailLoaded(this.caregiver);

  @override
  List<Object?> get props => [caregiver];
}

final class PatientCaregiverDetailDeleting extends PatientCaregiverDetailState {
  final ConnectedCaregiver caregiver;

  const PatientCaregiverDetailDeleting(this.caregiver);

  @override
  List<Object?> get props => [caregiver];
}

final class PatientCaregiverDetailError extends PatientCaregiverDetailState {
  final String message;

  const PatientCaregiverDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
