import 'package:dio/dio.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/features/alerts/data/models/patient_alert.dart';

class AlertService {
  final Dio _dio;

  AlertService({Dio? dio}) : _dio = dio ?? ApiHttpClient.dio;

  Future<PatientAlert> createAlert({
    required String patientId,
    required String alertType,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.createAlertEndpoint,
        data: {
          'patient_id': patientId,
          'alert_type': alertType,
        },
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode == 201 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] is Map) {
          return PatientAlert.fromJson(
            Map<String, dynamic>.from(data['data'] as Map),
          );
        }
      }
      throw Exception('Failed to create alert (${response.statusCode})');
    } on DioException catch (e) {
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Failed to create alert'),
      );
    }
  }

  Future<List<PatientAlert>> fetchPatientAlerts(String patientId) async {
    try {
      final response = await _dio.get(
        ApiConfig.patientAlertsEndpoint(patientId),
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load alerts (${response.statusCode})');
      }
      return _parseList(response.data);
    } on DioException catch (e) {
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Failed to load alerts'),
      );
    }
  }

  Future<PatientAlert> acknowledgeAlert(
    String alertId, {
    required String caregiverId,
  }) async {
    try {
      final response = await _dio.put(
        ApiConfig.alertByIdEndpoint(alertId),
        data: {'caregiver_id': caregiverId},
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['data'] is Map) {
          return PatientAlert.fromJson(
            Map<String, dynamic>.from(data['data'] as Map),
          );
        }
      }
      throw Exception('Failed to acknowledge alert (${response.statusCode})');
    } on DioException catch (e) {
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Failed to acknowledge alert'),
      );
    }
  }

  List<PatientAlert> _parseList(dynamic raw) {
    if (raw is! Map) return const [];
    final list = raw['data'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => PatientAlert.fromJson(Map<String, dynamic>.from(e)))
        .where((a) => a.id.isNotEmpty)
        .toList();
  }
}
