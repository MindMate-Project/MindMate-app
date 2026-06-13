import 'package:dio/dio.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/core/network/patient_context_store.dart';

/// Last known location reported by the active patient's tracking device.
class PatientDeviceLocation {
  const PatientDeviceLocation({
    this.patientName,
    this.deviceId,
    this.latitude,
    this.longitude,
    this.timestamp,
    this.battery,
  });

  final String? patientName;
  final String? deviceId;
  final double? latitude;
  final double? longitude;
  final DateTime? timestamp;
  final int? battery;

  /// True when the device has reported a usable coordinate pair.
  bool get hasCoordinates => latitude != null && longitude != null;

  factory PatientDeviceLocation.fromJson(Map<String, dynamic> data) {
    final device = data['device'];
    final d = device is Map ? device : const <dynamic, dynamic>{};

    double? toDouble(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));
    int? toInt(dynamic v) =>
        v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
    DateTime? toTime(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

    return PatientDeviceLocation(
      patientName: data['name']?.toString(),
      deviceId: d['deviceId']?.toString(),
      latitude: toDouble(d['latitude']),
      longitude: toDouble(d['longitude']),
      timestamp: toTime(d['timestamp']),
      battery: toInt(d['battery']),
    );
  }
}

/// Reads the active patient's device location from the backend
/// (`GET /api/device/location/:patientId`, caregiver-only).
class DeviceLocationService {
  DeviceLocationService();

  final Dio _dio = ApiHttpClient.dio;
  final PatientContextStore _patientContextStore = PatientContextStore();

  /// Returns the active patient's last device location, or `null` when no
  /// patient is selected or no tracking device is assigned (backend 404).
  /// Throws on auth/network errors so the UI can offer a retry.
  Future<PatientDeviceLocation?> getActivePatientLocation() async {
    final patientId = await _patientContextStore.getActivePatientId();
    if (patientId == null || patientId.isEmpty) return null;

    try {
      final response = await _dio.get(
        '/api/device/location/$patientId',
        options: await ApiHttpClient.authorizedOptions(),
      );
      final data = response.data;
      final inner = data is Map ? data['data'] : null;
      if (inner is Map) {
        return PatientDeviceLocation.fromJson(
          Map<String, dynamic>.from(inner),
        );
      }
      return null;
    } on DioException catch (e) {
      // 404 = patient has no device assigned (or not found) → treat as "no
      // location" rather than an error.
      if (e.response?.statusCode == 404) return null;
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? e.message ?? 'Failed to load location');
    }
  }
}
