import 'package:dio/dio.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import '../../domain/models/auth_response_model.dart';
import '../../domain/models/register_request.dart';

class AuthService {
  final Dio _dio;

  AuthService() : _dio = ApiHttpClient.dio;

  /// Helper method to handle errors and parse responses
  dynamic _handleResponse(Response response) {
    // Check if response is HTML (error page)
    if (response.data is String) {
      final dataString = (response.data as String).trim();
      if (dataString.toLowerCase().startsWith('<!doctype') ||
          dataString.toLowerCase().startsWith('<html')) {
        throw Exception(
          'Server returned HTML instead of JSON (Status: ${response.statusCode}). '
          'This usually means the endpoint URL is incorrect or the server is returning an error page.',
        );
      }
    }

    if (response.data is Map) {
      return response.data;
    }

    if (response.data is String) {
      return {'message': response.data};
    }

    return response.data;
  }

  /// Helper method to extract error message
  String _extractErrorMessage(dynamic error, String defaultMessage) {
    if (error is DioException) {
      if (error.response != null) {
        final responseData = error.response!.data;

        // Check if response is HTML
        if (responseData is String) {
          final dataString = responseData.trim();
          if (dataString.toLowerCase().startsWith('<!doctype') ||
              dataString.toLowerCase().startsWith('<html')) {
            return 'Server error: Received HTML instead of JSON (Status: ${error.response?.statusCode}). '
                'The endpoint may be incorrect or the server is down.';
          }
          return responseData;
        }

        // If it's a Map, extract error message
        if (responseData is Map) {
          return responseData['message'] ??
              responseData['error'] ??
              error.response?.statusMessage ??
              defaultMessage;
        }
      }

      // Handle connection errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timeout. Please check your internet connection.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to connect to server. Please check your internet connection.';
      }

      return error.message ?? defaultMessage;
    }
    return error.toString();
  }

  /// Register a new user
  /// Returns AuthResponse with user data (no token on registration)
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/api/auth/register',
        data: request.toJson(),
      );

      final responseBody = _handleResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse.fromJson(responseBody);
      } else {
        final responseMap = responseBody as Map<String, dynamic>;
        final errorMessage =
            responseMap['message'] ??
            responseMap['error'] ??
            'Registration failed';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Registration failed'));
    } catch (e) {
      throw Exception('Registration error: ${e.toString()}');
    }
  }

  /// Login with email and password
  /// Returns AuthResponse with user data and token
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );

      final responseBody = _handleResponse(response);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseBody);
      } else {
        final responseMap = responseBody as Map<String, dynamic>;
        final errorMessage =
            responseMap['message'] ?? responseMap['error'] ?? 'Login failed';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Login failed'));
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  /// Verify email account from the link token.
  /// GET /api/auth/verify/:token
  Future<Map<String, dynamic>> verifyAccount(String token) async {
    try {
      final response = await _dio.get('/api/auth/verify/$token');
      final responseBody = _handleResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Account verified.',
        };
      }
      final errorMessage =
          responseBody['message'] ??
          responseBody['error'] ??
          'Verification failed';
      return {'success': false, 'message': errorMessage};
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _extractErrorMessage(e, 'Verification failed'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Send password reset code to email
  /// Returns success message
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/api/auth/forgot-password',
        data: {'email': email},
      );

      final responseBody = _handleResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseBody['message'] ??
              'Password reset code sent to your email.',
        };
      } else {
        final errorMessage =
            responseBody['message'] ??
            responseBody['error'] ??
            'Failed to send reset code';
        return {'success': false, 'message': errorMessage};
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _extractErrorMessage(e, 'Failed to send reset code'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> verifyResetPassword(String code) async {
    try {
      final response = await _dio.post(
        '/api/auth/verify-reset-password',
        data: {'code': code},
      );

      final responseBody = _handleResponse(response);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Code verified.',
        };
      } else {
        final errorMessage =
            responseBody['message'] ??
            responseBody['error'] ??
            'Invalid or expired code';
        return {'success': false, 'message': errorMessage};
      }
    } on DioException catch (e) {
      return {
        'success': false,
        'message': _extractErrorMessage(e, 'Invalid or expired code'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<AuthResponse> resetPassword(
    String email,
    String code,
    String newPassword,
    String passwordConfirmation,
  ) async {
    try {
      final response = await _dio.post(
        '/api/auth/reset-password',
        data: {
          'email': email,
          'code': code,
          'password': newPassword,
          'passwordConfirmation': passwordConfirmation,
        },
      );

      final responseBody = _handleResponse(response);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseBody);
      } else {
        final errorMessage =
            responseBody['message'] ??
            responseBody['error'] ??
            'Password reset failed';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Password reset failed'));
    } catch (e) {
      throw Exception('Password reset error: ${e.toString()}');
    }
  }
}
