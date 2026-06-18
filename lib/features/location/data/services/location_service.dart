import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/features/location/data/models/location_exception.dart';
import 'package:mindmate/features/location/data/models/patient_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const _useDeviceLocationKey = 'location_use_device_for_testing';

  final Dio _dio;

  LocationService({Dio? dio}) : _dio = dio ?? ApiHttpClient.dio;

  Future<bool> getUseDeviceLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useDeviceLocationKey) ?? false;
  }

  Future<void> setUseDeviceLocation(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDeviceLocationKey, value);
  }

  Future<PatientLocation> resolveLocation({
    required String? patientId,
    required String patientName,
    required bool useDeviceLocation,
  }) async {
    final hasPatient = patientId != null && patientId.isNotEmpty;

    if (!hasPatient && !useDeviceLocation) {
      throw const LocationException('No patient selected.');
    }

    if (!hasPatient) {
      return _fetchDeviceLocation(patientName: patientName);
    }

    try {
      return await _fetchPatientLocation(
        patientId: patientId,
        patientName: patientName,
      );
    } catch (e) {
      if (!useDeviceLocation) {
        if (e is LocationException) rethrow;
        throw LocationException(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
      return _fetchDeviceLocation(patientName: patientName);
    }
  }

  Future<PatientLocation> _fetchPatientLocation({
    required String patientId,
    required String patientName,
  }) async {
    try {
      final location = await _fetchFromApi(
        patientId: patientId,
        patientName: patientName,
      );
      if (location != null && location.hasValidCoordinates) {
        return location;
      }
      throw const LocationException(
        "The patient's tracking device hasn't reported a location yet.",
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const LocationException(
          'No tracking device is assigned to this patient yet.',
          isRecoverable: false,
        );
      }
      if (e.response?.statusCode == 401) {
        throw const LocationException('Session expired. Please log in again.');
      }
      throw LocationException(
        ApiHttpClient.friendlyError(
          e,
          fallback: 'Failed to load location',
        ),
      );
    }
  }

  Future<PatientLocation> _fetchDeviceLocation({
    required String patientName,
  }) async {
    final position = await _currentPosition();
    final address = await _reverseGeocode(
      position.latitude,
      position.longitude,
    );

    return PatientLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address ??
          _coordinateAddress(position.latitude, position.longitude),
      updatedAt: position.timestamp,
      inSafeZone: true,
      zoneLabel: 'Current Location',
      patientName: patientName,
      isFallback: true,
    );
  }

  Future<PatientLocation?> _fetchFromApi({
    required String patientId,
    required String patientName,
  }) async {
    final response = await _dio.get(
      ApiConfig.deviceLocationEndpoint(patientId),
      options: await ApiHttpClient.authorizedOptions(),
    );

    if (response.statusCode != 200 || response.data == null) return null;

    final location = PatientLocation.fromApiJson(
      response.data,
      patientName: patientName,
    );
    if (!location.hasValidCoordinates) return null;

    if (location.address.isEmpty) {
      final resolved = await _reverseGeocode(
        location.latitude,
        location.longitude,
      );
      return location.copyWith(
        address: resolved ??
            _coordinateAddress(location.latitude, location.longitude),
      );
    }
    return location;
  }

  Future<Position> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException('Location permission denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return null;
      final p = places.first;
      final parts = [
        if (p.name?.isNotEmpty == true) p.name,
        if (p.street?.isNotEmpty == true) p.street,
        if (p.locality?.isNotEmpty == true) p.locality,
        if (p.administrativeArea?.isNotEmpty == true) p.administrativeArea,
        if (p.country?.isNotEmpty == true) p.country,
      ].whereType<String>().toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (e) {
      debugPrint(
        '[LocationService] Reverse geocode failed for ($lat, $lng): $e',
      );
      return null;
    }
  }

  static String _coordinateAddress(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
