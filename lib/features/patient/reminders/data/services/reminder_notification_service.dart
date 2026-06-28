import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:mindmate/features/memory/data/services/memory_training_service.dart';
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

  /// Uses the plugin initialized once in [MemoryTrainingService.init] (main).
  FlutterLocalNotificationsPlugin get _plugin =>
      MemoryTrainingService.instance.notificationsPlugin;

  final RemindersService _service = RemindersService();

  static const String _channelId = 'reminder_alarms';
  static const String _channelName = 'Reminder alarms';
  static const String _channelDesc =
      'Full-screen medication and appointment alarms.';

  static const String payloadPrefix = 'reminder_alarm';

  /// Distinct id range from MemoryTrainingService (9000s) to avoid collisions.
  static const int _baseId = 700000;

  /// Cap scheduled notifications to stay within platform limits (iOS allows 64
  /// pending). Reminders arrive sorted soonest-first, so we keep the nearest.
  static const int _maxScheduled = 60;

  static const String _trackedIdsKey = 'scheduled_reminder_ids';
  static const String _fsiGrantedKey = 'reminder_fsi_granted';

  /// Whether alarm delivery prerequisites are met (notifications, exact alarms,
  /// and on Android 14+ full-screen intent permission).
  Future<bool> hasFullScreenIntentPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;

    final notificationsEnabled = await android.areNotificationsEnabled();
    final exactAlarms = await android.canScheduleExactNotifications();
    if (notificationsEnabled != true || exactAlarms != true) return false;

    if (!_isAndroid14OrHigher()) return true;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fsiGrantedKey) ?? false;
  }

  /// Prompts for full-screen intent permission (Android 14+) and caches the result.
  Future<void> requestFullScreenIntentAccess() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    final fsiGranted = await android.requestFullScreenIntentPermission();
    if (fsiGranted != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fsiGrantedKey, fsiGranted);
    }
  }

  static bool _isAndroid14OrHigher() {
    if (kIsWeb || !Platform.isAndroid) return false;
    final version = Platform.operatingSystemVersion;
    final match = RegExp(r'(\d+)').firstMatch(version);
    if (match == null) return false;
    final major = int.tryParse(match.group(1)!);
    return major != null && major >= 14;
  }

  /// Fetches the patient's reminders and (re)schedules local notifications.
  /// Safe to call repeatedly (e.g. on every patient-home launch); it cancels the
  /// previously scheduled set first. On a network/auth error it leaves the
  /// existing scheduled notifications untouched.
  Future<void> syncFromServer() async {
    await _ensureChannel();

    final granted = await _ensurePermissions();
    if (!granted) {
      debugPrint(
        '[ReminderNotifications] sync aborted: notification permission denied',
      );
      return;
    }

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
    var skippedPast = 0;

    for (final r in reminders) {
      if (index >= _maxScheduled) break;
      final when = tz.TZDateTime.from(r.scheduledTime, tz.local);
      if (!when.isAfter(now)) {
        skippedPast++;
        continue;
      }

      // Do not skip isSent rows: the backend cron sets isSent when it *attempts*
      // FCM, even if push never reached the device. Local scheduling is the
      // reliable path on the patient phone.

      final id = _baseId + index;
      final ok = await _scheduleOne(id, when, r);
      if (!ok) continue;
      scheduledIds.add(id);
      index++;
    }

    await _saveTracked(scheduledIds);
    debugPrint(
      '[ReminderNotifications] synced ${scheduledIds.length} upcoming '
      '(${reminders.length} fetched, $skippedPast already past)',
    );
  }

  /// Cancels every reminder notification this service has scheduled.
  Future<void> cancelAll() async {
    await _cancelTracked();
    await _saveTracked(const []);
  }

  Future<bool> _scheduleOne(
    int id,
    tz.TZDateTime when,
    ReminderItem r,
  ) async {
    final (title, body) = _content(r);
    // Full-screen alarm: max importance + the alarm category make Android launch
    // the app over the lock screen when this fires. ongoing/autoCancel:false keep
    // it sticky so it can only be cleared by the in-app "Done" action.
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    final payload = '$payloadPrefix:$id:${r.id}';

    for (final mode in [
      AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ]) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        return true;
      } catch (e) {
        debugPrint(
          '[ReminderNotifications] schedule failed ($mode) for ${r.id} at $when: $e',
        );
      }
    }
    return false;
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
      // Full-screen intent permission (Android 14+); the manifest declares
      // USE_FULL_SCREEN_INTENT. Without it the alarm degrades to a heads-up only.
      final fsiGranted = await android.requestFullScreenIntentPermission();
      if (fsiGranted != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_fsiGrantedKey, fsiGranted);
      }
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
        importance: Importance.max,
        audioAttributesUsage: AudioAttributesUsage.alarm,
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
