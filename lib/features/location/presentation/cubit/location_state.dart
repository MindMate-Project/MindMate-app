import 'package:equatable/equatable.dart';
import 'package:mindmate/features/location/data/models/geofence_alert_event.dart';
import 'package:mindmate/features/location/data/models/patient_location.dart';
import 'package:mindmate/features/location/data/models/safe_zone.dart';

sealed class LocationState extends Equatable {
  const LocationState({required this.useDeviceLocation});

  final bool useDeviceLocation;

  @override
  List<Object?> get props => [useDeviceLocation];
}

class LocationInitial extends LocationState {
  const LocationInitial({super.useDeviceLocation = false});
}

class LocationLoading extends LocationState {
  const LocationLoading({required super.useDeviceLocation});
}

class LocationNoPatient extends LocationState {
  const LocationNoPatient({required super.useDeviceLocation});
}

class LocationLoaded extends LocationState {
  final PatientLocation location;
  final List<SafeZone> safeZones;
  final GeofenceAlertEvent? geofenceAlert;

  const LocationLoaded({
    required this.location,
    required super.useDeviceLocation,
    this.safeZones = const [],
    this.geofenceAlert,
  });

  bool get hasSafeZones => safeZones.isNotEmpty;

  LocationLoaded copyWith({
    PatientLocation? location,
    List<SafeZone>? safeZones,
    GeofenceAlertEvent? geofenceAlert,
    bool clearGeofenceAlert = false,
    bool? useDeviceLocation,
  }) {
    return LocationLoaded(
      location: location ?? this.location,
      safeZones: safeZones ?? this.safeZones,
      geofenceAlert:
          clearGeofenceAlert ? null : (geofenceAlert ?? this.geofenceAlert),
      useDeviceLocation: useDeviceLocation ?? this.useDeviceLocation,
    );
  }

  @override
  List<Object?> get props =>
      [location, safeZones, geofenceAlert, useDeviceLocation];
}

class LocationError extends LocationState {
  final String message;
  final bool isRecoverable;

  const LocationError({
    required this.message,
    required super.useDeviceLocation,
    this.isRecoverable = true,
  });

  @override
  List<Object?> get props => [message, useDeviceLocation, isRecoverable];
}
