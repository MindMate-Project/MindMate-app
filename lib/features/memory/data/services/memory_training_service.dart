import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:mindmate/features/memory/data/models/memory_item.dart';

class MemoryTrainingService {
  MemoryTrainingService._();
  static final MemoryTrainingService instance = MemoryTrainingService._();

  static const _enabledKey = 'memory_training_enabled';
  static const _lastShownIdKey = 'memory_training_last_shown_id';
  static const _timesKey = 'memory_training_times';
  static const _lastCountKey = 'memory_training_last_count';

  static const int _baseId = 9000;
  static const int minSlots = 1;
  static const int maxSlots = 6;

  static const List<TimeOfDay> _defaultTimes = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 19, minute: 0),
  ];

  static const String _channelId = 'memory_training';
  static const String _channelName = 'Memory training reminders';
  static const String _channelDesc =
      'Daily reminders to recall a random memory.';

  static const String _payloadPrefix = 'memory_drill';
  static const String _genericTitle = 'Memory training';
  static const String _genericBody = 'Tap to see a memory.';

  static const String _cacheSubdir = 'memory_training';

  late final FlutterLocalNotificationsPlugin _plugin;
  final Dio _imageDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.bytes,
    ),
  );

  /// Set during [init] when the app was cold-launched by a reminder alarm's
  /// full-screen intent. `main()` reads it after `runApp` to show the alarm
  /// once the navigator exists. `(notificationId, reminderId)`.
  (int, String)? pendingAlarmLaunch;

  /// Shared plugin initialized in [init]; used by geofence and reminder notifications.
  FlutterLocalNotificationsPlugin get notificationsPlugin => _plugin;

  /// Requests OS notification permission (Android 13+ / iOS). Safe to call repeatedly.
  Future<bool> ensureNotificationPermissions() => _requestPermissions();

  Future<void> init({
    required void Function(String? memoryId) onTap,
    void Function(String reminderId)? onReminderTap,
    void Function(int notificationId, String reminderId)? onReminderAlarm,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) async {
    _plugin = notificationsPlugin ?? FlutterLocalNotificationsPlugin();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (e) {
      debugPrint('[MemoryTraining] timezone init failed, using UTC: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
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
        final alarm = _parseAlarmPayload(payload);
        if (alarm != null) {
          onReminderAlarm?.call(alarm.$1, alarm.$2);
          return;
        }
        if (payload == _payloadPrefix) {
          onTap(null);
        } else if (payload.startsWith('$_payloadPrefix:')) {
          final id = payload.substring(_payloadPrefix.length + 1);
          onTap(id.isEmpty ? null : id);
        } else if (payload.startsWith('reminder:')) {
          final id = payload.substring('reminder:'.length);
          if (id.isNotEmpty) onReminderTap?.call(id);
        }
      },
    );

    // Cold start: if a reminder alarm's full-screen intent launched the app,
    // stash it so main() can show the alarm once the navigator is ready.
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        pendingAlarmLaunch = _parseAlarmPayload(
          launch!.notificationResponse?.payload,
        );
      }
    } catch (e) {
      debugPrint('[MemoryTraining] launch details failed: $e');
    }

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
    final prefs = await SharedPreferences.getInstance();
    final lastCount = prefs.getInt(_lastCountKey) ?? _defaultTimes.length;
    await _cancelRange(lastCount);
    await _clearImageCache();
    await prefs.setBool(_enabledKey, false);
  }

  /// Get the configured daily times, defaulting to [9:00, 14:00, 19:00].
  Future<List<TimeOfDay>> getTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_timesKey);
    if (raw == null || raw.isEmpty) return List<TimeOfDay>.from(_defaultTimes);
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => _parseTime(e.toString()))
          .whereType<TimeOfDay>()
          .toList();
      if (list.isEmpty) return List<TimeOfDay>.from(_defaultTimes);
      return list;
    } catch (e) {
      debugPrint('[MemoryTraining] times parse failed, using defaults: $e');
      return List<TimeOfDay>.from(_defaultTimes);
    }
  }

  /// Persist the user-chosen times. Caller is responsible for triggering a
  /// reschedule via [applyForPatient] with the current memory list.
  Future<void> setTimes(List<TimeOfDay> times) async {
    if (times.length < minSlots || times.length > maxSlots) {
      throw ArgumentError(
        'times must contain between $minSlots and $maxSlots entries.',
      );
    }
    final sorted = [...times]
      ..sort((a, b) {
        final am = a.hour * 60 + a.minute;
        final bm = b.hour * 60 + b.minute;
        return am.compareTo(bm);
      });
    final encoded = jsonEncode(sorted.map(_formatTime).toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timesKey, encoded);
  }

  Future<void> applyForPatient(List<MemoryItem> allMemories) async {
    final enabled = await isEnabled();
    final times = await getTimes();

    final prefs = await SharedPreferences.getInstance();
    final lastCount = prefs.getInt(_lastCountKey) ?? _defaultTimes.length;
    // Cancel every slot id that was either previously scheduled or that we
    // are about to overwrite. Covers the "count shrank" case.
    final toClear = lastCount > times.length ? lastCount : times.length;
    await _cancelRange(toClear);

    if (!enabled) {
      await _clearImageCache();
      await prefs.setInt(_lastCountKey, 0);
      return;
    }

    final picks = _pickDistinct(allMemories, times.length);
    final imagePaths = await Future.wait(picks.map(_ensureLocalImage));

    for (var i = 0; i < times.length; i++) {
      final t = times[i];
      final pick = i < picks.length ? picks[i] : null;
      final imagePath = i < imagePaths.length ? imagePaths[i] : null;
      final title = pick?.title.trim().isNotEmpty == true
          ? pick!.title.trim()
          : _genericTitle;
      final body = pick != null ? 'Remember $title? Tap to see.' : _genericBody;
      final payload = pick?.id != null && pick!.id!.isNotEmpty
          ? '$_payloadPrefix:${pick.id}'
          : _payloadPrefix;
      await _scheduleDaily(
        _baseId + 1 + i,
        hour: t.hour,
        minute: t.minute,
        title: title,
        body: body,
        payload: payload,
        imagePath: imagePath,
      );
    }

    await prefs.setInt(_lastCountKey, times.length);
  }

  Future<void> cancelForCaregiver() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCount = prefs.getInt(_lastCountKey) ?? _defaultTimes.length;
    await _cancelRange(lastCount);
  }

  Future<void> _cancelRange(int count) async {
    for (var i = 1; i <= count && i <= maxSlots; i++) {
      await _plugin.cancel(_baseId + i);
    }
  }

  Future<bool> _requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final ok = await androidImpl.requestNotificationsPermission();
      if (ok == false) return false;
    }

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
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
    String? imagePath,
  }) async {
    final scheduled = _nextInstanceOf(hour, minute);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: imagePath != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imagePath),
              largeIcon: FilePathAndroidBitmap(imagePath),
              contentTitle: title,
              summaryText: body,
              hideExpandedLargeIcon: true,
            )
          : null,
    );
    final iosDetails = DarwinNotificationDetails(
      attachments: imagePath != null
          ? [DarwinNotificationAttachment(imagePath)]
          : null,
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
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

  /// Show a one-off notification immediately. If [memoriesForPicture] is
  /// provided and contains a photo memory, the BigPictureStyle is used so the
  /// caregiver can confirm image-rich notifications render correctly.
  Future<void> showTestNotification({
    List<MemoryItem>? memoriesForPicture,
  }) async {
    String? imagePath;
    String title = 'Test notification';
    String body =
        'If you can read this, notifications work. Tap to open the drill.';
    String payload = _payloadPrefix;

    if (memoriesForPicture != null) {
      final photos = memoriesForPicture
          .where(
            (m) =>
                m.type == MemoryType.photo &&
                m.imageUrl != null &&
                m.imageUrl!.isNotEmpty,
          )
          .toList();
      if (photos.isNotEmpty) {
        final pick = photos[Random().nextInt(photos.length)];
        imagePath = await _ensureLocalImage(pick);
        if (pick.title.trim().isNotEmpty) {
          title = pick.title.trim();
          body = 'Remember $title? Tap to see.';
        }
        if (pick.id != null && pick.id!.isNotEmpty) {
          payload = '$_payloadPrefix:${pick.id}';
        }
      }
    }

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: imagePath != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imagePath),
              largeIcon: FilePathAndroidBitmap(imagePath),
              contentTitle: title,
              summaryText: body,
              hideExpandedLargeIcon: true,
            )
          : null,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: imagePath != null
          ? [DarwinNotificationAttachment(imagePath)]
          : null,
    );

    await _plugin.show(
      9999,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // ── BigPicture image download ────────────────────────────────────────────

  Future<String?> _ensureLocalImage(MemoryItem m) async {
    if (m.type != MemoryType.photo) return null;
    final url = m.imageUrl;
    if (url == null || url.isEmpty) return null;
    final id = m.id;
    if (id == null || id.isEmpty) return null;

    try {
      final dir = await _ensureCacheDir();
      final safeId = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File('${dir.path}/$safeId.jpg');
      if (await file.exists()) {
        final len = await file.length();
        if (len > 0) return file.path;
      }
      final downloadUrl = _maybeCloudinaryThumb(url);
      final response = await _imageDio.get<List<int>>(downloadUrl);
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) return null;
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('[MemoryTraining] image download failed for $url: $e');
      return null;
    }
  }

  Future<Directory> _ensureCacheDir() async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/$_cacheSubdir');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _maybeCloudinaryThumb(String url) {
    try {
      final uri = Uri.parse(url);
      if (!uri.host.contains('cloudinary.com')) return url;
      // Inject a width transformation segment after `/upload/` for a smaller
      // payload. Falls through unchanged if the URL doesn't have that segment.
      final marker = '/upload/';
      final idx = url.indexOf(marker);
      if (idx < 0) return url;
      if (url.contains('/upload/w_')) return url; // already transformed
      return url.replaceFirst(marker, '${marker}w_720,c_limit/');
    } catch (_) {
      return url;
    }
  }

  Future<void> _clearImageCache() async {
    try {
      final base = await getApplicationCacheDirectory();
      final dir = Directory('${base.path}/$_cacheSubdir');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[MemoryTraining] cache clear failed: $e');
    }
  }

  // ── Time serialization helpers ───────────────────────────────────────────

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Parses a `reminder_alarm:<notificationId>:<reminderId>` payload into its
  /// numeric notification id and reminder id, or null if it isn't one.
  static (int, String)? _parseAlarmPayload(String? payload) {
    const prefix = 'reminder_alarm:';
    if (payload == null || !payload.startsWith(prefix)) return null;
    final rest = payload.substring(prefix.length);
    final sep = rest.indexOf(':');
    if (sep <= 0) return null;
    final notificationId = int.tryParse(rest.substring(0, sep));
    final reminderId = rest.substring(sep + 1);
    if (notificationId == null || reminderId.isEmpty) return null;
    return (notificationId, reminderId);
  }

  @visibleForTesting
  FlutterLocalNotificationsPlugin get plugin => _plugin;
}
