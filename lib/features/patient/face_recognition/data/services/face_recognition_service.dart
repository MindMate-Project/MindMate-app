import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/core/network/api_http_client.dart';

class FaceRecognitionService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    receiveTimeout: const Duration(seconds: 30),
    connectTimeout: const Duration(seconds: 30),
  ));

  static Future<Map<String, dynamic>> identifyFace(String imagePath, {String? token}) async {
    try {
      debugPrint('🔄 Sending image to API...');
      debugPrint('📍 URL: ${ApiConfig.identifyFaceEndpoint}');
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath, filename: 'face.jpg'),
      });
      
      // The backend authenticates this endpoint with the Bearer token below
      // (protect middleware); it does not check X-API-Key.
      Map<String, dynamic> headers = {
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('🔑 Token included in request');
      }
      
      debugPrint('🚀 Sending request via Dio using FormData...');
      
      final response = await _dio.post(
        ApiConfig.identifyFaceEndpoint,
        data: formData,
        options: Options(
          headers: headers,
          validateStatus: (status) => status! < 500, // Handle 400 gracefully instead of throwing Exception
        ),
      );
      
      debugPrint('📨 Response status: ${response.statusCode}');
      debugPrint('📨 Response body: ${response.data}');
      
      final data = response.data;
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Success! Data: $data');
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'data': {
            'recognized': false,
            'message': 'Person not found in database',
          }
        };
      } else {
        debugPrint('❌ Server error: ${response.statusCode}');
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
          'details': data,
        };
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        debugPrint('⏱️ Timeout: $e');
        return {
          'success': false,
          'error': 'Request timeout. Please check your internet connection.',
        };
      }
      debugPrint('🌐 Network or Dio error: $e');
      return {
        'success': false,
        'error': 'Network error: ${e.message}',
      };
    } catch (e) {
      debugPrint('❌ Error: $e');
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
