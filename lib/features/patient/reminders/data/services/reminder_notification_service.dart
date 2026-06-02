import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';

/// Schedules on-device local notifications for the patient's reminders.
///
/// Delivery used to rely on a backend FCM push that never fired (no device
/// tokens were ever registered). Instead we fetch the reminder rows the server
/// already generates — the appointment time, its 24h/1h lead-time rows, and each
/// medication dose — and schedule a local notification for each upcoming one via
/// the OS alarm scheduler. The plugin is initialized once by
/// `MemoryTrainingService.init` in `main()`, so this only schedules.
class ReminderNotificationService {
  ReminderNotificationService._();
  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final RemindersService _service = RemindersService();

  static const String _channelId = 'reminders';
  static const String _channelName = 'Reminders';
  static const String _channelDesc =
      'Appointment and medication reminders.';

  static const String payloadPrefix = 'reminder';

  /// Distinct id range from MemoryTrainingService (9000s) to avoid collisions.
  static const int _baseId = 700000;

  /// Cap scheduled notifications to stay within platform limits (iOS allows 64
  /// pending). Reminders arrive sorted soonest-first, so we keep the nearest.
  static const int _maxScheduled = 60;

  static const String _trackedIdsKey = 'scheduled_reminder_ids';

  /// Fetches the patient's reminders and (re)schedules local notifications.
  /// Safe to call repeatedly (e.g. on every patient-home launch); it cancels the
  /// previously scheduled set first. On a network/auth error it leaves the
  /// existing scheduled notifications untouched.
  Future<void> syncFromServer() async {
    final granted = await _ensurePermissions();
    if (!granted) return;
    await _ensureChannel();

    List<ReminderItem> reminders;
    try {
      reminders = await _service.getRemindersForScheduling();
    } catch (e) {
      debugPrint('[ReminderNotifications] sync skipped: $e');
      return;
    }

    await _cancelTracked();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledIds = <int>[];
    var index = 0;

    for (final r in reminders) {
      if (index >= _maxScheduled) break;
      if (r.isSent) continue;
      final when = tz.TZDateTime.from(r.scheduledTime, tz.local);
      if (!when.isAfter(now)) continue;

      final id = _baseId + index;
      await _scheduleOne(id, when, r);
      scheduledIds.add(id);
      index++;
    }

    await _saveTracked(scheduledIds);
  }

  /// Cancels every reminder notification this service has scheduled.
  Future<void> cancelAll() async {
    await _cancelTracked();
    await _saveTracked(const []);
  }

  Future<void> _scheduleOne(
    int id,
    tz.TZDateTime when,
    ReminderItem r,
  ) async {
    final (title, body) = _content(r);
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '$payloadPrefix:${r.id}',
    );
  }

  (String, String) _content(ReminderItem r) {
    if (r.type.toLowerCase() == 'appointment') {
      final doctor = (r.doctorName ?? '').trim();
      final location = (r.location ?? '').trim();
      final title = doctor.isNotEmpty ? 'Appointment: $doctor' : 'Appointment reminder';
      final body = location.isNotEmpty
          ? 'You have an appointment at $location'
          : 'You have an upcoming appointment';
      return (title, body);
    }
    final med = (r.medicineName ?? '').trim();
    final dose = (r.dosage ?? '').trim();
    final title = med.isNotEmpty ? 'Medicine: $med' : 'Medication reminder';
    final body = dose.isNotEmpty ? 'Time to take $dose' : 'Time to take your medicine';
    return (title, body);
  }

  Future<bool> _ensurePermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final ok = await android.requestNotificationsPermission();
      // Best-effort: ask for exact-alarm permission (Android 13+). The manifest
      // already declares SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM.
      await android.requestExactAlarmsPermission();
      if (ok == false) return false;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final ok = await ios.requestPermissions(alert: true, badge: true, sound: true);
      if (ok == false) return false;
    }
    return true;
  }

  Future<void> _ensureChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _cancelTracked() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_trackedIdsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final ids = (jsonDecode(raw) as List).cast<int>();
      for (final id in ids) {
        await _plugin.cancel(id);
      }
    } catch (e) {
      debugPrint('[ReminderNotifications] cancel failed: $e');
    }
  }

  Future<void> _saveTracked(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trackedIdsKey, jsonEncode(ids));
  }
}
