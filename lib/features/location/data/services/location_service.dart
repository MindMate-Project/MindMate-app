import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/features/location/data/models/location_exception.dart';
import 'package:mindmate/features/location/data/models/patient_location.dart';
import 'package:mindmate/features/location/data/models/safe_zone.dart';
import 'package:mindmate/features/location/data/services/safe_zone_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const _useDeviceLocationKey = 'location_use_device_for_testing';

  final Dio _dio;
  final SafeZoneService _safeZoneService;

  LocationService({
    Dio? dio,
    SafeZoneService? safeZoneService,
  })  : _dio = dio ?? ApiHttpClient.dio,
        _safeZoneService = safeZoneService ?? SafeZoneService();

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
    final result = await resolveLocationWithZones(
      patientId: patientId,
      patientName: patientName,
      useDeviceLocation: useDeviceLocation,
    );
    return result.location;
  }

  /// Fetches patient location and safe zones together so zone status stays in sync.
  Future<({PatientLocation location, List<SafeZone> safeZones})>
      resolveLocationWithZones({
    required String? patientId,
    required String patientName,
    required bool useDeviceLocation,
  }) async {
    final hasPatient = patientId != null && patientId.isNotEmpty;

    if (!hasPatient && !useDeviceLocation) {
      throw const LocationException('No patient selected.');
    }

    if (!hasPatient) {
      final location = await _fetchDeviceLocation(patientName: patientName);
      return (location: location, safeZones: const <SafeZone>[]);
    }

    if (useDeviceLocation) {
      final location = await _fetchDeviceLocation(patientName: patientName);
      final zones = await _safeZoneService.getSafeZones(patientId);
      return (
        location: SafeZone.applyZoneStatus(location: location, zones: zones),
        safeZones: zones,
      );
    }

    try {
      final bundle = await _fetchPatientLocationBundle(
        patientId: patientId,
        patientName: patientName,
      );
      var zones = bundle.safeZones;
      if (zones.isEmpty) {
        zones = await _safeZoneService.getSafeZones(patientId);
      }
      return (
        location: SafeZone.applyZoneStatus(
          location: bundle.location,
          zones: zones,
        ),
        safeZones: zones,
      );
    } catch (e) {
      if (e is LocationException) rethrow;
      throw LocationException(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<List<SafeZone>> getSafeZones(String patientId) =>
      _safeZoneService.getSafeZones(patientId);

  Future<SafeZone> addSafeZone(SafeZone zone) =>
      _safeZoneService.addSafeZone(zone);

  Future<SafeZone> updateSafeZone(SafeZone zone) =>
      _safeZoneService.updateSafeZone(zone);

  Future<void> removeSafeZone(String patientId, String zoneId) =>
      _safeZoneService.removeSafeZone(patientId, zoneId);

  Future<void> clearAllSafeZones(String patientId) =>
      _safeZoneService.clearAllSafeZones(patientId);

  Future<({PatientLocation location, List<SafeZone> safeZones})>
      _fetchPatientLocationBundle({
    required String patientId,
    required String patientName,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.deviceLocationEndpoint(patientId),
        options: await ApiHttpClient.authorizedOptions(),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw const LocationException(
          "The patient's tracking device hasn't reported a location yet.",
        );
      }

      final raw = response.data;
      var location = PatientLocation.fromApiJson(
        raw,
        patientName: patientName,
      );
      if (!location.hasValidCoordinates) {
        throw const LocationException(
          "The patient's tracking device hasn't reported a location yet.",
        );
      }

      if (location.address.isEmpty) {
        final resolved = await _reverseGeocode(
          location.latitude,
          location.longitude,
        );
        location = location.copyWith(
          address: resolved ??
              _coordinateAddress(location.latitude, location.longitude),
        );
      }

      final parsedZone =
          _safeZoneService.parseFromLocationPayload(patientId, raw);
      final zones = parsedZone != null && parsedZone.isRenderable
          ? [parsedZone]
          : <SafeZone>[];

      return (location: location, safeZones: zones);
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

  static String _coordinateAddress(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  /// Live GPS updates for device-location (testing) mode.
  Stream<Position> watchDevicePosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  Future<PatientLocation> buildDeviceLocationFromPosition(
    Position position, {
    required String patientName,
  }) async {
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
      isDeviceOnline: true,
    );
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
}
