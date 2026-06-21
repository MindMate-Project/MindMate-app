import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/core/network/api_http_client.dart';

class FaceRecognitionService {
  Future<Map<String, dynamic>> identifyFace(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath, filename: 'face.jpg'),
      });

      final response = await ApiHttpClient.dio.post(
        ApiConfig.identifyFaceEndpoint,
        data: formData,
        options: await ApiHttpClient.authorizedOptions(),
      );

      final data = response.data;
      final code = response.statusCode ?? 0;

      if (code == 200 || code == 201) {
        return {
          'success': true,
          'data': data,
        };
      }
      if (code == 404) {
        return {
          'success': true,
          'data': {
            'recognized': false,
            'message': 'Person not found in database',
          },
        };
      }
      return {
        'success': false,
        'error': 'Server error: $code',
        'details': data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': ApiHttpClient.friendlyError(
          e,
          fallback: 'Could not identify the face.',
        ),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error: $e',
      };
    }
  }

  /// Registers a known person the [patientId] should recognize.
  ///
  /// Caregiver action: sends first/last name, relationship and [photos] (the
  /// backend requires at least 3) to `POST /api/face/patient/register-face`.
  /// Uses the shared authorized Dio so the caregiver's Bearer token is attached.
  /// Returns `(ok, error)` where [error] carries the server message on failure
  /// (e.g. "Only patients can register faces" until the backend grants caregivers
  /// permission).
  static Future<({bool ok, String? error})> registerKnownPerson({
    required String patientId,
    required String firstName,
    required String lastName,
    required String relationship,
    required List<File> photos,
  }) async {
    try {
      final formData = FormData.fromMap({
        'patientId': patientId,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'relationship': relationship.trim(),
        // Backend multer field name for the face photos (confirmed against the
        // deployed API — 'images'/'photos' return "Unexpected field").
        'files': [
          for (final file in photos)
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split(RegExp(r'[\\/]')).last,
            ),
        ],
      });

      final response = await ApiHttpClient.dio.post(
        ApiConfig.registerFaceEndpoint,
        data: formData,
        options: await ApiHttpClient.authorizedOptions(),
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
}
