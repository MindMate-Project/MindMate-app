import 'package:equatable/equatable.dart';
import 'package:mindmate/features/assignments/data/models/assigned_patient_row.dart';

/// The patient currently selected for caregiver-scoped features.
class ActivePatient extends Equatable {
  final String id;
  final String name;

  const ActivePatient({required this.id, required this.name});

  factory ActivePatient.fromRow(AssignedPatientRow row) => ActivePatient(
        id: row.patientId,
        name: row.name,
      );

  @override
  List<Object?> get props => [id, name];
}
