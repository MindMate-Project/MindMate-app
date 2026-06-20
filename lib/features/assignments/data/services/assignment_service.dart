import 'package:dio/dio.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/features/assignments/data/models/assigned_patient_row.dart';
import 'package:mindmate/features/assignments/data/models/connected_caregiver.dart';
import 'package:mindmate/features/assignments/data/models/pending_caregiver_request.dart';
import 'package:mindmate/features/caregiver/patients/data/models/caregiver_patient_detail.dart';

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

  /// GET /api/caregiver/patients/:patientId — full profile for an assigned
  /// patient (caregiver role).
  Future<CaregiverPatientDetail> fetchPatientDetail(String patientId) async {
    try {
      final response = await ApiHttpClient.dio.get(
        '/api/caregiver/patients/$patientId',
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load patient (${response.statusCode})');
      }
      final json = _extractPatientJson(response.data);
      final detail = CaregiverPatientDetail.fromJson(json);
      if (detail.id.isEmpty) {
        throw Exception('Patient not found');
      }
      return detail;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Patient not found or no longer assigned to you.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not load patient'),
      );
    }
  }

  /// PATCH /api/caregiver/patients/update/:patientId
  Future<CaregiverPatientDetail> updatePatient({
    required String patientId,
    required String name,
    DateTime? dateOfBirth,
    required PatientMedicalNotes medicalNotes,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'medicalNotes': medicalNotes.toJson(),
    };
    if (dateOfBirth != null) {
      body['dateOfBirth'] =
          '${dateOfBirth.year.toString().padLeft(4, '0')}-'
          '${dateOfBirth.month.toString().padLeft(2, '0')}-'
          '${dateOfBirth.day.toString().padLeft(2, '0')}';
    }

    try {
      final response = await ApiHttpClient.dio.patch(
        '/api/caregiver/patients/update/$patientId',
        data: body,
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update patient (${response.statusCode})');
      }
      final json = _extractPatientJson(response.data);
      final detail = CaregiverPatientDetail.fromJson(json);
      if (detail.id.isEmpty) {
        return fetchPatientDetail(patientId);
      }
      return detail;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not update patient'),
      );
    }
  }

  /// DELETE /api/caregiver/patients/remove/:patientId
  Future<void> removePatient(String patientId) async {
    try {
      final response = await ApiHttpClient.dio.delete(
        '/api/caregiver/patients/remove/$patientId',
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to remove patient (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not remove patient'),
      );
    }
  }

  /// GET /api/patient/caregivers — the signed-in patient's connected
  /// caregivers. Pass [patientId] to resolve relationship from `patients[]`
  /// when the API returns full caregiver documents.
  Future<List<ConnectedCaregiver>> fetchMyCaregivers({String? patientId}) async {
    try {
      final response = await ApiHttpClient.dio.get(
        '/api/patient/caregivers',
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load caregivers (${response.statusCode})');
      }
      return _extractList(response.data)
          .whereType<Map>()
          .map(
            (m) => ConnectedCaregiver.fromJson(
              Map<String, dynamic>.from(m),
              patientId: patientId,
            ),
          )
          .where((c) => c.id.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not load caregivers'),
      );
    }
  }

  /// GET /api/patient/caregivers/:caregiverId — full info for one connected
  /// caregiver (patient role). [patientId] resolves relationship/connectedAt
  /// from the caregiver's `patients[]` link entry.
  Future<ConnectedCaregiver> fetchCaregiverDetail(
    String caregiverId, {
    required String patientId,
  }) async {
    try {
      final response = await ApiHttpClient.dio.get(
        '/api/patient/caregivers/$caregiverId',
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to load caregiver (${response.statusCode})');
      }
      final json = _extractCaregiverJson(response.data);
      final detail = ConnectedCaregiver.fromDetailJson(
        json,
        patientId: patientId,
      );
      if (detail.id.isEmpty) {
        throw Exception('Caregiver not found');
      }
      return detail;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Caregiver not found or no longer connected to you.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not load caregiver'),
      );
    }
  }

  /// DELETE /api/patient/caregivers/remove/:caregiverId
  Future<void> removeCaregiverFromPatient(String caregiverId) async {
    try {
      final response = await ApiHttpClient.dio.delete(
        '/api/patient/caregivers/remove/$caregiverId',
        options: await ApiHttpClient.authorizedOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to remove caregiver (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      throw Exception(
        ApiHttpClient.friendlyError(e, fallback: 'Could not remove caregiver'),
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

  Map<String, dynamic> _extractPatientJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['patient'] ?? data['user'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    throw Exception('Unexpected server response.');
  }

  Map<String, dynamic> _extractCaregiverJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['caregiver'] ?? data['user'];
      if (nested is Map<String, dynamic>) return nested;
      return data;
    }
    throw Exception('Unexpected server response.');
  }
}
