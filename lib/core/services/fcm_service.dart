import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/core/navigation/app_navigation.dart';
import 'package:mindmate/core/navigation/app_router.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';

/// Registers and unregisters the device FCM token with the MindMate backend.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  static const _fcmTokenPath = '/api/users/fcm-token';
  static const _fcmChannelId = 'fcm_general';
  static const _fcmChannelName = 'Push Notifications';
  static const _fcmChannelDescription =
      'General push notifications from MindMate.';
  static const _authTokenKey = 'auth_token';
  static const _secureStorage = FlutterSecureStorage();

  StreamSubscription<String>? _tokenRefreshSub;

  /// FCM tap that launched the app from a terminated state; consumed after splash.
  RemoteMessage? pendingOpenedMessage;

  /// POST /api/users/fcm-token — sends the current FCM token to the backend.
  Future<void> registerToken({int maxAttempts = 3}) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final jwt = await _secureStorage.read(key: _authTokenKey);
        if (jwt == null || jwt.isEmpty) {
          debugPrint(
            '[FcmService] No JWT in secure storage — skipping FCM registration.',
          );
          return;
        }

        final token = await _resolveFcmToken();
        if (token == null || token.isEmpty) {
          debugPrint(
            '[FcmService] FCM token is null or empty — skipping registration.',
          );
          return;
        }

        await ApiHttpClient.warmUp();

        debugPrint('[FcmService] Sending FCM token to backend (attempt $attempt)…');
        await ApiHttpClient.dio.post(
          _fcmTokenPath,
          data: {'token': token},
          options: await ApiHttpClient.authorizedOptions(),
        );
        debugPrint('[FcmService] FCM token registered successfully.');
        debugPrint('[FcmService] Device token (Firebase Console test): $token');
        return;
      } on DioException catch (e) {
        final message = ApiHttpClient.friendlyError(
          e,
          fallback: 'FCM token registration failed.',
        );
        debugPrint(
          '[FcmService] registerToken attempt $attempt failed: $message',
        );
        if (attempt == maxAttempts) return;
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('[FcmService] registerToken attempt $attempt failed: $e');
        if (attempt == maxAttempts) return;
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  /// DELETE /api/users/fcm-token — removes the token from the backend.
  Future<void> deleteToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await ApiHttpClient.dio.delete(
          _fcmTokenPath,
          data: {'token': token},
          options: await ApiHttpClient.authorizedOptions(),
        );
      }
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[FcmService] deleteToken failed: $e');
    }
  }

  /// Re-registers whenever Firebase rotates the device token.
  /// Call after authentication — not from [main] before a session exists.
  void startTokenRefreshListener() {
    if (_tokenRefreshSub != null) return;

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        debugPrint('[FcmService] onTokenRefresh: $newToken');
        if (!await _hasActiveSession()) {
          debugPrint(
            '[FcmService] No active session — skipping refreshed token sync.',
          );
          return;
        }
        await registerToken();
      },
    );
  }

  /// Ensures Android 13+ / iOS notification permission is granted for tray UI.
  Future<void> ensureNotificationPermissions(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final androidImpl = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Creates the tray channel used for foreground FCM messages.
  Future<void> ensureAndroidChannel(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final androidImpl = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _fcmChannelId,
        _fcmChannelName,
        description: _fcmChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  /// Shows a push in the tray when the app is foregrounded (or in a background
  /// isolate for data-only payloads).
  Future<void> showRemoteMessage(
    RemoteMessage message,
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    final notification = message.notification;
    final title =
        notification?.title ?? message.data['title']?.toString() ?? 'MindMate';
    final body =
        notification?.body ?? message.data['body']?.toString() ?? '';
    if (title.isEmpty && body.isEmpty) return;

    await plugin.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _fcmChannelId,
          _fcmChannelName,
          channelDescription: _fcmChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Routes the user after they tap a reminder push (background or cold start).
  void handleReminderMessageOpened(RemoteMessage message, AuthState authState) {
    if (authState is! AuthSuccess) return;

    final reminderId = message.data['reminderId']?.toString();
    final user = authState.user;

    if (user.isPatient) {
      if (reminderId != null && reminderId.isNotEmpty) {
        showReminderAlarm(message.hashCode, reminderId);
      }
      return;
    }

    if (user.isCaregiver) {
      if (reminderId != null && reminderId.isNotEmpty) {
        AppRouter.router.push(AppRoutes.reminderDetail(reminderId));
      } else {
        AppRouter.router.push(AppRoutes.patientReminders);
      }
    }
  }

  /// Minimal local-notifications bootstrap for the FCM background isolate.
  Future<FlutterLocalNotificationsPlugin> createBackgroundNotificationsPlugin() async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(
      const InitializationSettings(android: androidInit),
    );
    await ensureAndroidChannel(plugin);
    return plugin;
  }

  Future<String?> _resolveFcmToken() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) return token;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  Future<bool> _hasActiveSession() async {
    final jwt = await _secureStorage.read(key: _authTokenKey);
    return jwt != null && jwt.isNotEmpty;
  }
}
