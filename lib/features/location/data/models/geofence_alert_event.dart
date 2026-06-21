import 'package:equatable/equatable.dart';

/// In-app + notification alert raised when a patient leaves all safe zones.
class GeofenceAlertEvent extends Equatable {
  final String patientId;
  final String patientName;
  final String zoneName;
  final String address;
  final DateTime timestamp;

  const GeofenceAlertEvent({
    required this.patientId,
    required this.patientName,
    required this.zoneName,
    required this.address,
    required this.timestamp,
  });

  String get message {
    if (address.isNotEmpty) {
      return '$patientName is outside $zoneName — $address';
    }
    return '$patientName is outside $zoneName.';
  }

  @override
  List<Object?> get props =>
      [patientId, patientName, zoneName, address, timestamp];
}
