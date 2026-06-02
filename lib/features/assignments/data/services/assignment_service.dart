import 'package:dio/dio.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/features/assignments/data/models/assigned_patient_row.dart';
import 'package:mindmate/features/assignments/data/models/pending_caregiver_request.dart';

class AssignmentService {
  Future<void> sendAssignmentRequest({
    required String patientEmail,
    required String relationshipApiValue,
  }) async {
    try {
      final response = await ApiHttpClient.dio.post(
        '/api/caregiver/patients/assignment-request',
        data: {
          'patientEmail': patientEmail.trim(),
          'relationship': relationshipApiValue,
        },
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Request failed (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(
          e,
          fallback: 'Could not send assignment request',
        ),
      );
    }
  }

  Future<List<PendingCaregiverRequest>> fetchPendingAssignmentRequests() async {
    try {
      final response = await ApiHttpClient.dio.get(
        '/api/patient/assignment-requests',
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load requests (${response.statusCode})');
      }
      final data = response.data;
      final list = _extractList(data);
      final out = <PendingCaregiverRequest>[];
      for (final item in list) {
        if (item is Map) {
          final parsed = PendingCaregiverRequest.tryParse(Map<String, dynamic>.from(item));
          if (parsed != null) out.add(parsed);
        }
      }
      return out;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(
          e,
          fallback: 'Could not load assignment requests',
        ),
      );
    }
  }

  Future<void> respondToAssignmentRequest({
    required String caregiverId,
    required bool accept,
  }) async {
    final action = accept ? 'accept' : 'reject';
    try {
      final response = await ApiHttpClient.dio.post(
        '/api/patient/assignment-requests/respond/$caregiverId',
        data: {'action': action},
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not update request'),
      );
    }
  }

  Future<List<AssignedPatientRow>> fetchCaregiverPatients() async {
    try {
      final response = await ApiHttpClient.dio.get(
        '/api/caregiver/patients',
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load patients (${response.statusCode})');
      }
      final list = _extractList(response.data);
      return list
          .whereType<Map>()
          .map((m) => AssignedPatientRow.fromJson(Map<String, dynamic>.from(m)))
          .where((r) => r.patientId.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not load patients'),
      );
    }
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    if (data is List) return data;
    return const [];
  }
}
