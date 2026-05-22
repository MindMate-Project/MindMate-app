import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:mindmate/features/memory/data/models/memory_item.dart';

class MemoryTrainingService {
  MemoryTrainingService._();
  static final MemoryTrainingService instance = MemoryTrainingService._();

  static const _enabledKey = 'memory_training_enabled';
  static const _lastShownIdKey = 'memory_training_last_shown_id';

  static const int _id9am = 9001;
  static const int _id2pm = 9002;
  static const int _id7pm = 9003;

  static const String _channelId = 'memory_training';
  static const String _channelName = 'Memory training reminders';
  static const String _channelDesc =
      'Daily reminders to recall a random memory.';

  static const String _payloadPrefix = 'memory_drill';
  static const String _genericTitle = 'Memory training';
  static const String _genericBody = 'Tap to see a memory.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init({required void Function(String? memoryId) onTap}) async {
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      debugPrint('[MemoryTraining] timezone init failed, using UTC: $e');
    }

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == null) return;
        if (payload == _payloadPrefix) {
          onTap(null);
        } else if (payload.startsWith('$_payloadPrefix:')) {
          final id = payload.substring(_payloadPrefix.length + 1);
          onTap(id.isEmpty ? null : id);
        }
      },
    );

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
  }

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<bool> enable() async {
    final granted = await _requestPermissions();
    if (!granted) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    return true;
  }

  Future<void> disable() async {
    await _cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
  }

  Future<void> applyForPatient(List<MemoryItem> allMemories) async {
    final enabled = await isEnabled();
    await _cancelAll();
    if (!enabled) return;

    final picks = _pickDistinct(allMemories, 3);
    final slots = [
      (_id9am, 9, 0),
      (_id2pm, 14, 0),
      (_id7pm, 19, 0),
    ];

    for (var i = 0; i < slots.length; i++) {
      final (id, hour, minute) = slots[i];
      final pick = i < picks.length ? picks[i] : null;
      final title = pick?.title.trim().isNotEmpty == true
          ? pick!.title.trim()
          : _genericTitle;
      final body = pick != null
          ? 'Remember $title? Tap to see.'
          : _genericBody;
      final payload = pick?.id != null && pick!.id!.isNotEmpty
          ? '$_payloadPrefix:${pick.id}'
          : _payloadPrefix;
      await _scheduleDaily(
        id,
        hour: hour,
        minute: minute,
        title: title,
        body: body,
        payload: payload,
      );
    }
  }

  Future<void> cancelForCaregiver() async {
    await _cancelAll();
  }

  Future<void> _cancelAll() async {
    await _plugin.cancel(_id9am);
    await _plugin.cancel(_id2pm);
    await _plugin.cancel(_id7pm);
  }

  Future<bool> _requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final ok = await androidImpl.requestNotificationsPermission();
      if (ok == false) return false;
    }

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final ok = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (ok == false) return false;
    }

    return true;
  }

  Future<void> _scheduleDaily(
    int id, {
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String payload,
  }) async {
    final scheduled = _nextInstanceOf(hour, minute);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  List<MemoryItem> _pickDistinct(List<MemoryItem> all, int count) {
    if (all.isEmpty || count <= 0) return const [];
    final pool = List<MemoryItem>.from(all)..shuffle();
    if (pool.length >= count) return pool.take(count).toList();
    final result = <MemoryItem>[];
    while (result.length < count) {
      result.add(pool[result.length % pool.length]);
    }
    return result;
  }

  Future<MemoryItem?> pickRandomMemory(List<MemoryItem> all) async {
    if (all.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getString(_lastShownIdKey);

    var candidates = all.where((m) => m.id != null && m.id != lastId).toList();
    if (candidates.isEmpty) candidates = all;

    final picked = candidates[Random().nextInt(candidates.length)];
    if (picked.id != null && picked.id!.isNotEmpty) {
      await prefs.setString(_lastShownIdKey, picked.id!);
    }
    return picked;
  }

  Future<void> rememberShown(String id) async {
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastShownIdKey, id);
  }

  Future<List<PendingNotificationRequest>> debugPending() {
    return _plugin.pendingNotificationRequests();
  }

  Future<void> showTestNotification() async {
    await _plugin.show(
      9999,
      'Test notification',
      'If you can read this, notifications work. Tap to open the drill.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _payloadPrefix,
    );
  }

  @visibleForTesting
  FlutterLocalNotificationsPlugin get plugin => _plugin;
}
