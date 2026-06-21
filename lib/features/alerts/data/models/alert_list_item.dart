import 'package:equatable/equatable.dart';

import 'package:mindmate/features/alerts/data/models/patient_alert.dart';

class AlertListItem extends Equatable {
  final PatientAlert alert;
  final String patientName;

  const AlertListItem({required this.alert, required this.patientName});

  @override
  List<Object?> get props => [alert, patientName];
}
