import 'package:dio/dio.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/features/auth/domain/models/user_model.dart';

class ProfileService {
  final Dio _dio;

  ProfileService()
      : _dio = ApiHttpClient.dio;

  Future<Options> _authOptions() => ApiHttpClient.authorizedOptions();

  Future<User> getMyProfile({required String role}) async {
    final endpoint = role == 'caregiver' ? '/api/caregiver' : '/api/patient';
    try {
      final response = await _dio.get(endpoint, options: await _authOptions());
      if (response.statusCode == 200) {
        final data = response.data;
        final Map<String, dynamic> json = _extractUserJson(data);
        return User.fromJson(json);
      }
      throw Exception('Failed to load profile (${response.statusCode})');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      final msg = _extractMessage(e.response?.data) ?? 'Failed to load profile';
      throw Exception(msg);
    }
  }

  Future<User> updateMyProfile({
    required String role,
    required String name,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    final endpoint =
        role == 'caregiver' ? '/api/caregiver/update' : '/api/patient/update';

    final Map<String, dynamic> body = {'name': name};

    // Backend payloads vary slightly between patient/caregiver.
    if (role == 'caregiver') {
      if (phone != null && phone.trim().isNotEmpty) {
        body['phone'] = phone.trim();
      }
    } else {
      if (phone != null && phone.trim().isNotEmpty) {
        body['phoneNumber'] = phone.trim();
      }
      if (gender != null && gender.trim().isNotEmpty) {
        body['gender'] = gender.trim().toLowerCase();
      }
      if (dateOfBirth != null) {
        final yyyyMmDd =
            '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
        body['dateOfBirth'] = yyyyMmDd;
      }
    }

    try {
      final response = await _dio.patch(
        endpoint,
        data: body,
        options: await _authOptions(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final Map<String, dynamic> json = _extractUserJson(data);
        return User.fromJson(json);
      }
      throw Exception('Failed to update profile (${response.statusCode})');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      final msg =
          _extractMessage(e.response?.data) ?? 'Failed to update profile';
      throw Exception(msg);
    }
  }

  Map<String, dynamic> _extractUserJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      final dynamic user =
          data['user'] ?? data['data'] ?? data['profile'] ?? data;
      if (user is Map<String, dynamic>) return user;
      // Some endpoints might return { caregiver: {...} } or { patient: {...} }
      for (final key in ['caregiver', 'patient']) {
        final val = data[key];
        if (val is Map<String, dynamic>) return val;
      }
      return data;
    }
    throw Exception('Unexpected server response.');
  }

  String? _extractMessage(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return null;
  }
}

