import 'package:dio/dio.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/core/network/patient_context_store.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';

class RemindersService {
  final Dio _dio;
  final PatientContextStore _patientContextStore = PatientContextStore();

  RemindersService() : _dio = ApiHttpClient.dio;

  Future<String?> _getPatientId() => _patientContextStore.getActivePatientId();

  Future<Options> _authOptions() => ApiHttpClient.authorizedOptions();

  /// Patient endpoint:
  /// GET /api/reminders/patient/:patientId
  Future<List<ReminderItem>> getPatientReminders() async {
    final patientId = await _getPatientId();
    if (patientId == null || patientId.isEmpty) {
      throw Exception(
        'No connected patient. Please connect at least one patient first.',
      );
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

