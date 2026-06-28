import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/core/network/api_http_client.dart';

typedef KnownPeopleActionResult = ({bool ok, String? error});

class KnownPeopleService {
  final Dio _dio;

  KnownPeopleService() : _dio = ApiHttpClient.dio;

  Future<Options> _authOptions() => ApiHttpClient.authorizedOptions();

  /// `POST /api/face/patient/register`
  ///
  /// Patients omit [patientId]. Caregivers must pass the assigned patient's id.
  Future<KnownPeopleActionResult> registerKnownPerson({
    required String firstName,
    required String lastName,
    required String relationship,
    required List<File> photos,
    String? patientId,
  }) async {
    try {
      final formData = await _buildFaceForm(
        firstName: firstName,
        lastName: lastName,
        relationship: relationship,
        photos: photos,
        patientId: patientId,
      );

      final response = await _dio.post(
        ApiConfig.registerKnownPersonEndpoint,
        data: formData,
        options: await _authOptions(),
      );

      final code = response.statusCode ?? 0;
      if (code == 200 || code == 201) {
        return (ok: true, error: null);
      }
      return (
        ok: false,
        error: ApiHttpClient.messageFromResponseData(response.data) ??
            'Failed to register the person ($code)',
      );
    } on DioException catch (e) {
      return (
        ok: false,
        error: ApiHttpClient.friendlyError(
          e,
          fallback: 'Could not register the person.',
        ),
      );
    } catch (e) {
      return (ok: false, error: 'Error: $e');
    }
  }

  /// `POST /api/face/patient/add-photos`
  ///
  /// Patients omit [patientId]. Caregivers must pass the assigned patient's id.
  Future<KnownPeopleActionResult> addPhotosToKnownPerson({
    required String firstName,
    required String lastName,
    required List<File> photos,
    String? patientId,
  }) async {
    try {
      final formData = await _buildFaceForm(
        firstName: firstName,
        lastName: lastName,
        photos: photos,
        patientId: patientId,
      );

      final response = await _dio.post(
        ApiConfig.addFacePhotosEndpoint,
        data: formData,
        options: await _authOptions(),
      );

      final code = response.statusCode ?? 0;
      if (code == 200 || code == 201) {
        return (ok: true, error: null);
      }
      return (
        ok: false,
        error: ApiHttpClient.messageFromResponseData(response.data) ??
            'Failed to add photos ($code)',
      );
    } on DioException catch (e) {
      return (
        ok: false,
        error: ApiHttpClient.friendlyError(
          e,
          fallback: 'Could not add photos.',
        ),
      );
    } catch (e) {
      return (ok: false, error: 'Error: $e');
    }
  }

  static Future<FormData> _buildFaceForm({
    required String firstName,
    required String lastName,
    required List<File> photos,
    String? relationship,
    String? patientId,
  }) async {
    final map = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      if (relationship != null && relationship.trim().isNotEmpty)
        'relationship': relationship.trim().toLowerCase(),
      if (patientId != null && patientId.trim().isNotEmpty)
        'patientId': patientId.trim(),
      'files': [
        for (final file in photos)
          await MultipartFile.fromFile(
            file.path,
            filename: file.path.split(RegExp(r'[\\/]')).last,
          ),
      ],
    };
    return FormData.fromMap(map);
  }
}
