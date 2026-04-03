import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';

class RemindersService {
  final Dio _dio;

  RemindersService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<String?> _getPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('patient_id');
  }

  Future<Options> _authOptions() async {
    final token = await _getToken();
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  /// Patient endpoint:
  /// GET /api/reminders/patient/:patientId
  Future<List<ReminderItem>> getPatientReminders() async {
    final patientId = await _getPatientId();
    if (patientId == null || patientId.isEmpty) {
      throw Exception('Patient ID not found. Please log in again.');
    }

    final response = await _dio.get(
      '/api/reminders/patient/$patientId',
      options: await _authOptions(),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        return data
            .map((json) => ReminderItem.fromJson(
                  json as Map<String, dynamic>,
                ))
            .toList();
      }
      throw Exception('Unexpected reminders response format.');
    }

    throw Exception('Failed to load reminders (${response.statusCode})');
  }
}

