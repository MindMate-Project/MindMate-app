import 'package:dio/dio.dart';
import 'package:mindmate/core/network/api_http_client.dart';

class DeviceService {
  /// POST /api/device/assign-device — links an IoT device to a patient.
  Future<void> assignDevice({
    required String deviceId,
    required String patientEmail,
  }) async {
    try {
      final response = await ApiHttpClient.dio.post(
        '/api/device/assign-device',
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
}
