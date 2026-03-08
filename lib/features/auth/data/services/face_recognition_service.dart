import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mindmate/core/config/api_config.dart';

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
      
      Map<String, dynamic> headers = {
        'Accept': 'application/json',
        'X-API-Key': ApiConfig.apiKey,
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
}
