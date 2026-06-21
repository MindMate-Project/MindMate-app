import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mindmate/features/alerts/data/services/alert_service.dart';
import 'package:mindmate/features/location/data/models/geofence_alert_event.dart';
import 'package:mindmate/features/location/data/models/patient_location.dart';
import 'package:mindmate/features/location/data/models/safe_zone.dart';
import 'package:mindmate/features/memory/data/services/memory_training_service.dart';

/// Detects safe-zone exits during location polling and raises backend + local alerts.
class GeofenceAlertService {
  static const _alertType = 'geofence';
  static const _channelId = 'safe_zone_alerts';
  static const _channelName = 'Safe zone alerts';
  static const _channelDesc =
      'Alerts when a patient leaves their caregiver-defined safe zone.';
  static const _notificationBaseId = 800000;

  final AlertService _alertService;
  final FlutterLocalNotificationsPlugin _notifications;

  final Map<String, bool> _lastInZone = {};
  final Set<String> _outsideAlertSent = {};

  GeofenceAlertService({
    AlertService? alertService,
    FlutterLocalNotificationsPlugin? notifications,
  }) : _alertService = alertService ?? AlertService(),
       _notifications =
           notifications ?? MemoryTrainingService.instance.notificationsPlugin;

  void resetPatient(String patientId) {
    _lastInZone.remove(patientId);
    _outsideAlertSent.remove(patientId);
  }

  /// Returns an alert event when a new outside-zone alert is raised.
  Future<GeofenceAlertEvent?> onLocationUpdate({
    required String patientId,
    required String patientName,
    required PatientLocation location,
    required List<SafeZone> safeZones,
  }) async {
    if (patientId.isEmpty || safeZones.isEmpty) {
      resetPatient(patientId);
      return null;
    }

    final match = SafeZone.locate(
      safeZones,
      location.latitude,
      location.longitude,
    );
    final inZone = match.inAny;
    final wasInZone = _lastInZone[patientId];

    if (inZone) {
      _lastInZone[patientId] = true;
      _outsideAlertSent.remove(patientId);
      return null;
    }

    final shouldAlert = wasInZone == true || wasInZone == null;
    if (!shouldAlert || _outsideAlertSent.contains(patientId)) {
      _lastInZone[patientId] = false;
      return null;
    }

    final zoneLabel = safeZones.length == 1
        ? safeZones.first.displayName
        : 'safe zones';

    debugPrint(
      '[GeofenceAlert] raising alert for $patientId at '
      '(${location.latitude}, ${location.longitude})',
    );

    final event = await _raiseExitAlert(
      patientId: patientId,
      patientName: patientName,
      zoneName: zoneLabel,
      location: location,
    );

    if (event != null) {
      _outsideAlertSent.add(patientId);
    }
    _lastInZone[patientId] = false;
    return event;
  }

  Future<GeofenceAlertEvent?> _raiseExitAlert({
    required String patientId,
    required String patientName,
    required String zoneName,
    required PatientLocation location,
  }) async {
    try {
      await _alertService.createAlert(
        patientId: patientId,
        alertType: _alertType,
      );
      debugPrint('[GeofenceAlert] API alert created');
    } catch (e) {
      debugPrint('[GeofenceAlert] API alert failed: $e');
    }

    await _showLocalNotification(
      patientId: patientId,
      patientName: patientName,
      zoneName: zoneName,
      address: location.address,
    );

    return GeofenceAlertEvent(
      patientId: patientId,
      patientName: patientName,
      zoneName: zoneName,
      address: location.address,
      timestamp: DateTime.now(),
    );
  }

  Future<void> _showLocalNotification({
    required String patientId,
    required String patientName,
    required String zoneName,
    required String address,
  }) async {
    try {
      final granted = await _requestPermissions();
      if (!granted) {
        debugPrint('[GeofenceAlert] notification permission denied');
        return;
      }

      await _ensureChannel();

      final body = address.isNotEmpty
          ? '$patientName is outside $zoneName — $address'
          : '$patientName is outside $zoneName.';

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      await _notifications.show(
        _notificationBaseId + patientId.hashCode.abs() % 10000,
        'Safe zone alert',
        body,
        const NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: 'geofence:$patientId',
      );
      debugPrint('[GeofenceAlert] local notification shown');
    } catch (e) {
      debugPrint('[GeofenceAlert] local notification failed: $e');
    }
  }

  Future<bool> _requestPermissions() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final ok = await androidImpl.requestNotificationsPermission();
      if (ok == false) return false;
    }

    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == false) return false;
    }

    return true;
  }

  Future<void> _ensureChannel() async {
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );
  }
}
