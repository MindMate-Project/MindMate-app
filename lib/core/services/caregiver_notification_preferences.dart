import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caregiver toggle for Flutter-side alert workarounds (client geofence detection,
/// local notifications, in-app banners). When off, only cloud push (FCM) should
/// deliver alerts.
class CaregiverNotificationPreferences {
  CaregiverNotificationPreferences._();
  static final CaregiverNotificationPreferences instance =
      CaregiverNotificationPreferences._();

  static const _flutterSideAlertsKey = 'caregiver_flutter_side_alerts';

  bool _flutterSideAlertsEnabled = true;
  bool _loaded = false;

  final ValueNotifier<int> revision = ValueNotifier(0);

  bool get flutterSideAlertsEnabled => _flutterSideAlertsEnabled;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _flutterSideAlertsEnabled = prefs.getBool(_flutterSideAlertsKey) ?? true;
    _loaded = true;
    revision.value++;
  }

  Future<void> setFlutterSideAlertsEnabled(bool enabled) async {
    if (!_loaded) await load();
    if (_flutterSideAlertsEnabled == enabled) return;

    _flutterSideAlertsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flutterSideAlertsKey, enabled);
    revision.value++;
  }
}
