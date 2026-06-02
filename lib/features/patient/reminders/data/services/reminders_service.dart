import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/core/network/patient_context_store.dart';
import 'package:mindmate/features/patient/reminders/data/mappers/reminder_api_mapper.dart';
import 'package:mindmate/features/patient/reminders/data/models/notify_before_options.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/utils/reminder_filters.dart';

class RemindersService {
  final Dio _dio;
  final PatientContextStore _patientContextStore = PatientContextStore();

  RemindersService() : _dio = ApiHttpClient.dio;

  Future<String?> _getPatientId() => _patientContextStore.getActivePatientId();

  Future<Options> _authOptions() => ApiHttpClient.authorizedOptions();

  List<ReminderItem> _parseCreatedReminders(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is List) {
        return inner
            .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['_id'] != null) {
        return [ReminderItem.fromJson(data)];
      }
    }
    if (data is List) {
      return data
          .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ReminderItem>> _postReminder(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(
        '/api/reminders',
        data: body,
        options: await _authOptions(),
      );
      if (response.statusCode == 201) {
        return _parseCreatedReminders(response.data);
      }
      throw Exception('Failed to create reminder (${response.statusCode})');
    } on DioException catch (e) {
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? e.message ?? 'Failed to create reminder');
    }
  }

  Future<void> _putReminder(String id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put(
        '/api/reminders/$id',
        data: body,
        options: await _authOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw Exception('Failed to update reminder (${response.statusCode})');
    } on DioException catch (e) {
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? e.message ?? 'Failed to update reminder');
    }
  }

  Future<({String patientId, String caregiverId})> _actorIds(
    String caregiverId,
  ) async {
    final patientId = await _getPatientId();
    if (patientId == null || patientId.isEmpty) {
      throw Exception(
        'No connected patient. Please connect at least one patient first.',
      );
    }
    if (caregiverId.isEmpty) {
      throw Exception('Caregiver account is required to create reminders.');
    }
    return (patientId: patientId, caregiverId: caregiverId);
  }

  /// Drops auto-generated notification rows the user did not request (DELETE /api/reminders/:id).
  Future<void> _pruneAppointmentNotifications(
    List<ReminderItem> created,
    NotifyBeforeOptions notify,
  ) async {
    for (final item in created) {
      final offset = ReminderFilters.notificationOffset(item);
      if (offset == null) continue;
      if (notify.selectedOffsets.contains(offset)) continue;
      await deleteReminder(item.id);
    }
  }

  /// POST /api/reminders — appointment.
  Future<void> createAppointment({
    required String caregiverId,
    required String doctorName,
    required String specialty,
    required String location,
    required String appointmentTypeUi,
    required DateTime appointmentDate,
    required TimeOfDay appointmentTime,
    required NotifyBeforeOptions notifyBefore,
    String? notes,
  }) async {
    final ids = await _actorIds(caregiverId);
    final scheduled = ReminderApiMapper.mergeDateAndTime(
      appointmentDate,
      appointmentTime,
    );

    final created = await _postReminder({
      'type': 'appointment',
      'patient': ids.patientId,
      'caregiver': ids.caregiverId,
      'scheduledTime': ReminderApiMapper.toInstantIso(scheduled),
      'doctorName': doctorName.trim(),
      'specialty': specialty.trim(),
      'location': location.trim(),
      'appointmentType':
          ReminderApiMapper.appointmentTypeFromUi(appointmentTypeUi),
      'appointmentDate': ReminderApiMapper.toDateIso(appointmentDate),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });

    await _pruneAppointmentNotifications(created, notifyBefore);
  }

  /// PUT /api/reminders/:id — appointment (partial update).
  Future<void> updateAppointment({
    required String id,
    required String caregiverId,
    required String doctorName,
    required String specialty,
    required String location,
    required String appointmentTypeUi,
    required DateTime appointmentDate,
    required TimeOfDay appointmentTime,
    String? notes,
  }) async {
    final ids = await _actorIds(caregiverId);
    final scheduled = ReminderApiMapper.mergeDateAndTime(
      appointmentDate,
      appointmentTime,
    );

    await _putReminder(id, {
      'scheduledTime': ReminderApiMapper.toInstantIso(scheduled),
      'doctorName': doctorName.trim(),
      'specialty': specialty.trim(),
      'location': location.trim(),
      'appointmentType':
          ReminderApiMapper.appointmentTypeFromUi(appointmentTypeUi),
      'appointmentDate': ReminderApiMapper.toDateIso(appointmentDate),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'patient': ids.patientId,
      'caregiver': ids.caregiverId,
    });
  }

  /// POST /api/reminders — medication.
  Future<void> createMedication({
    required String caregiverId,
    required String medicineName,
    required String dosage,
    required String formUi,
    required String frequencyUi,
    required int timesPerDay,
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay time,
    required NotifyBeforeOptions notifyBefore,
  }) async {
    final ids = await _actorIds(caregiverId);
    final scheduled = ReminderApiMapper.mergeDateAndTime(startDate, time);
    final frequency = ReminderApiMapper.frequencyFromUi(frequencyUi);

    await _postReminder({
      'type': 'medication',
      'patient': ids.patientId,
      'caregiver': ids.caregiverId,
      'scheduledTime': ReminderApiMapper.toInstantIso(scheduled),
      'medicineName': medicineName.trim(),
      'dosage': dosage.trim(),
      'form': ReminderApiMapper.medicationFormFromUi(formUi),
      'frequency': frequency,
      'timesPerDay': timesPerDay,
      'startDate': ReminderApiMapper.toDateIso(startDate),
      if (frequency == 'daily' || frequency == 'weekly')
        'endDate': ReminderApiMapper.toDateIso(endDate),
    });

    // Medication dose rows are generated server-side and scheduled on-device by
    // ReminderNotificationService on the patient's device, so there is no local
    // queue to write here. (`notifyBefore` is retained for API symmetry with
    // appointments; per-dose lead-time alerts are a future enhancement.)
  }

  /// PUT /api/reminders/:id — medication (partial update).
  Future<void> updateMedication({
    required String id,
    required String caregiverId,
    required String medicineName,
    required String dosage,
    required String formUi,
    required String frequencyUi,
    required int timesPerDay,
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay time,
  }) async {
    final ids = await _actorIds(caregiverId);
    final scheduled = ReminderApiMapper.mergeDateAndTime(startDate, time);
    final frequency = ReminderApiMapper.frequencyFromUi(frequencyUi);

    await _putReminder(id, {
      'scheduledTime': ReminderApiMapper.toInstantIso(scheduled),
      'medicineName': medicineName.trim(),
      'dosage': dosage.trim(),
      'form': ReminderApiMapper.medicationFormFromUi(formUi),
      'frequency': frequency,
      'timesPerDay': timesPerDay,
      'startDate': ReminderApiMapper.toDateIso(startDate),
      if (frequency == 'daily' || frequency == 'weekly')
        'endDate': ReminderApiMapper.toDateIso(endDate),
      'patient': ids.patientId,
      'caregiver': ids.caregiverId,
    });
  }

  /// GET /api/reminders/patient/:patientId — all rows for the active patient.
  Future<List<ReminderItem>> _fetchPatientReminders() async {
    final patientId = await _getPatientId();
    if (patientId == null || patientId.isEmpty) {
      throw Exception(
        'No connected patient. Please connect at least one patient first.',
      );
    }

    try {
      final response = await _dio.get(
        '/api/reminders/patient/$patientId',
        options: await _authOptions(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data
              .map((json) => ReminderItem.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        throw Exception('Unexpected reminders response format.');
      }
      throw Exception('Failed to load reminders (${response.statusCode})');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? e.message ?? 'Failed to load reminders');
    }
  }

  /// Rows shown on the calendar/list (notification-only lead-time rows hidden).
  Future<List<ReminderItem>> getPatientReminders() async {
    final all = await _fetchPatientReminders();
    return all.where(ReminderFilters.isCalendarDisplay).toList();
  }

  /// Every row — including the 24h/1h appointment lead-time rows — used to
  /// schedule on-device local notifications.
  Future<List<ReminderItem>> getRemindersForScheduling() =>
      _fetchPatientReminders();

  /// GET /api/reminders/:id
  Future<ReminderItem> getReminderById(String id) async {
    try {
      final response = await _dio.get(
        '/api/reminders/$id',
        options: await _authOptions(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return ReminderItem.fromJson(data);
        }
        throw Exception('Unexpected reminder response format.');
      }
      throw Exception('Failed to load reminder (${response.statusCode})');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? e.message ?? 'Failed to load reminder');
    }
  }

  /// DELETE /api/reminders/:id
  Future<void> deleteReminder(String id) async {
    try {
      final response = await _dio.delete(
        '/api/reminders/$id',
        options: await _authOptions(),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete reminder (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? e.message ?? 'Failed to delete reminder');
    }
  }
}
