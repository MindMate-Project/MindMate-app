import 'package:equatable/equatable.dart';
import 'package:mindmate/features/location/data/models/patient_location.dart';

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

  const LocationLoaded({
    required this.location,
    required super.useDeviceLocation,
  });

  @override
  List<Object?> get props => [location, useDeviceLocation];
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
