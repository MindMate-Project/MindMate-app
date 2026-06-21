import 'package:equatable/equatable.dart';

enum AlertType { geofence, sos, unknown }

AlertType parseAlertType(String raw) {
  final normalized = raw.trim().toLowerCase();
  switch (normalized) {
    case 'geofence':
      return AlertType.geofence;
    case 'sos':
      return AlertType.sos;
    default:
      return AlertType.unknown;
  }
}

extension AlertTypeX on AlertType {
  String get apiValue {
    switch (this) {
      case AlertType.geofence:
        return 'geofence';
      case AlertType.sos:
        return 'sos';
      case AlertType.unknown:
        return 'unknown';
    }
  }

  String get displayTitle {
    switch (this) {
      case AlertType.geofence:
        return 'Left safe zone';
      case AlertType.sos:
        return 'SOS alert';
      case AlertType.unknown:
        return 'Unknown alert';
    }
  }
}

class PatientAlert extends Equatable {
  final String id;
  final String patientId;
  final AlertType type;
  final String rawType;
  final DateTime timestamp;
  final String? acknowledgedBy;

  const PatientAlert({
    required this.id,
    required this.patientId,
    required this.type,
    required this.rawType,
    required this.timestamp,
    this.acknowledgedBy,
  });

  bool get isAcknowledged =>
      acknowledgedBy != null && acknowledgedBy!.trim().isNotEmpty;

  String get alertType => rawType;

  String get displayTitle {
    if (type == AlertType.unknown) {
      return rawType.replaceAll('_', ' ');
    }
    return type.displayTitle;
  }

  factory PatientAlert.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final patientId =
        json['patient_id']?.toString() ?? json['patientId']?.toString() ?? '';
    final rawType =
        json['alert_type']?.toString() ?? json['alertType']?.toString() ?? '';
    final ts = json['timestamp']?.toString();
    final acknowledged = json['acknowledged_by'] ?? json['acknowledgedBy'];

    return PatientAlert(
      id: id,
      patientId: patientId,
      type: parseAlertType(rawType),
      rawType: rawType,
      timestamp: DateTime.tryParse(ts ?? '')?.toLocal() ?? DateTime.now(),
      acknowledgedBy: acknowledged?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    type,
    rawType,
    timestamp,
    acknowledgedBy,
  ];
}
