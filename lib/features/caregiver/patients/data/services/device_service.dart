import 'package:dio/dio.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/features/location/data/models/safe_zone.dart';

class DeviceService {
  final Dio _dio;

  DeviceService({Dio? dio}) : _dio = dio ?? ApiHttpClient.dio;

  /// POST /api/device/assign-device — links an IoT device to a patient.
  Future<void> assignDevice({
    required String deviceId,
    required String patientEmail,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.assignDeviceEndpoint,
        data: {
          'deviceId': deviceId.trim(),
          'patientEmail': patientEmail.trim(),
        },
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to assign device (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not assign device'),
      );
    }
  }

  /// DELETE /api/device/remove/:patientId — unlinks the IoT device.
  Future<void> removeDevice(String patientId) async {
    if (patientId.isEmpty) return;
    try {
      final response = await _dio.delete(
        ApiConfig.removeDeviceEndpoint(patientId),
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove device (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) return;
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not remove device'),
      );
    }
  }

  /// Reads the caregiver-defined safe zone from the device location payload.
  Future<SafeZone?> fetchSafeZone(String patientId) async {
    if (patientId.isEmpty) return null;
    try {
      final response = await _dio.get(
        ApiConfig.deviceLocationEndpoint(patientId),
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200 || response.data == null) return null;
      final zone = SafeZone.fromHomeLocation(
        patientId: patientId,
        raw: response.data,
      );
      if (zone != null) return zone;
      return fetchSafeZoneFromPatientProfile(patientId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return fetchSafeZoneFromPatientProfile(patientId);
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not load safe zone'),
      );
    }
  }

  /// Fallback when the location payload does not embed homeLocation.
  Future<SafeZone?> fetchSafeZoneFromPatientProfile(String patientId) async {
    if (patientId.isEmpty) return null;
    try {
      final response = await _dio.get(
        '/api/caregiver/patients/$patientId',
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200 || response.data == null) return null;
      return SafeZone.fromHomeLocation(
        patientId: patientId,
        raw: response.data,
      );
    } on DioException {
      return null;
    }
  }

  /// PATCH /api/device/safe-zone/:patientId — caregiver sets the home geofence.
  Future<SafeZone> setSafeZone({
    required String patientId,
    required double lat,
    required double lng,
    required double radiusMeters,
    String name = 'Home',
  }) async {
    try {
      final response = await _dio.patch(
        ApiConfig.deviceSafeZoneEndpoint(patientId),
        data: {
          'lat': lat,
          'lng': lng,
          'radiusMeters': radiusMeters,
        },
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to set safe zone (${response.statusCode})');
      }
      final zone = SafeZone.fromHomeLocation(
        patientId: patientId,
        raw: response.data,
        name: name,
      );
      if (zone != null) return zone;
      return SafeZone(
        id: patientId,
        patientId: patientId,
        latitude: lat,
        longitude: lng,
        radiusMeters: radiusMeters,
        name: name,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not save safe zone'),
      );
    }
  }

  /// DELETE /api/device/safe-zone/:patientId — turns geofence alerting off.
  Future<void> removeSafeZone(String patientId) async {
    if (patientId.isEmpty) return;
    try {
      final response = await _dio.delete(
        ApiConfig.deviceSafeZoneEndpoint(patientId),
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to remove safe zone (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) return;
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not remove safe zone'),
      );
    }
  }
}
