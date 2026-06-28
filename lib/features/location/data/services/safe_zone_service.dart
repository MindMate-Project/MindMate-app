import 'dart:convert';

import 'package:mindmate/features/caregiver/patients/data/services/device_service.dart';
import 'package:mindmate/features/location/data/models/safe_zone.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists caregiver safe zones via the device safe-zone API, with local cache
/// fallback so zones still display when the location payload omits homeLocation.
class SafeZoneService {
  static String _listKey(String patientId) => 'safe_zones_$patientId';
  static String _legacyKey(String patientId) => 'safe_zone_$patientId';

  final DeviceService _deviceService;
  SharedPreferences? _prefs;

  SafeZoneService({DeviceService? deviceService})
      : _deviceService = deviceService ?? DeviceService();

  Future<SharedPreferences> _ensurePrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<List<SafeZone>> getSafeZones(String patientId) async {
    if (patientId.isEmpty) return const [];

    final fromApi = await _deviceService.fetchSafeZone(patientId);
    if (fromApi != null && fromApi.isRenderable) {
      await _saveLocal(patientId, [fromApi]);
      return [fromApi];
    }

    return _readLocal(patientId);
  }

  Future<SafeZone> addSafeZone(SafeZone zone) async {
    final saved = await _deviceService.setSafeZone(
      patientId: zone.patientId,
      lat: zone.latitude,
      lng: zone.longitude,
      radiusMeters: zone.radiusMeters,
      name: zone.name,
    );
    await _saveLocal(zone.patientId, [saved]);
    return saved;
  }

  Future<SafeZone> updateSafeZone(SafeZone zone) async {
    final saved = await _deviceService.setSafeZone(
      patientId: zone.patientId,
      lat: zone.latitude,
      lng: zone.longitude,
      radiusMeters: zone.radiusMeters,
      name: zone.name,
    );
    await _saveLocal(zone.patientId, [saved]);
    return saved;
  }

  Future<void> removeSafeZone(String patientId, String zoneId) async {
    await _deviceService.removeSafeZone(patientId);
    await _clearLocal(patientId);
  }

  Future<void> clearAllSafeZones(String patientId) async {
    await _deviceService.removeSafeZone(patientId);
    await _clearLocal(patientId);
  }

  /// Parses a safe zone from a device-location response without a second request.
  SafeZone? parseFromLocationPayload(String patientId, dynamic raw) =>
      SafeZone.fromHomeLocation(patientId: patientId, raw: raw);

  Future<List<SafeZone>> _readLocal(String patientId) async {
    final prefs = await _ensurePrefs();
    final rawList = prefs.getString(_listKey(patientId));
    if (rawList != null && rawList.isNotEmpty) {
      return _parseList(rawList, patientId);
    }
    return _migrateLegacyZone(prefs, patientId);
  }

  Future<void> _saveLocal(String patientId, List<SafeZone> zones) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(
      _listKey(patientId),
      jsonEncode(zones.map((z) => z.toJson()).toList()),
    );
  }

  Future<void> _clearLocal(String patientId) async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_listKey(patientId));
    await prefs.remove(_legacyKey(patientId));
  }

  List<SafeZone> _parseList(String raw, String patientId) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) {
            final zone = SafeZone.fromJson(Map<String, dynamic>.from(e));
            if (zone.patientId.isEmpty) {
              return zone.copyWith(patientId: patientId);
            }
            return zone;
          })
          .where((z) => z.id.isNotEmpty && z.isRenderable)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<SafeZone>> _migrateLegacyZone(
    SharedPreferences prefs,
    String patientId,
  ) async {
    final legacy = prefs.getString(_legacyKey(patientId));
    if (legacy == null || legacy.isEmpty) return const [];

    try {
      final zone = SafeZone.fromJson(
        jsonDecode(legacy) as Map<String, dynamic>,
      );
      final migrated = zone.copyWith(
        id: zone.id.isEmpty ? patientId : zone.id,
        patientId: patientId,
      );
      if (!migrated.isRenderable) return const [];
      await _saveLocal(patientId, [migrated]);
      await prefs.remove(_legacyKey(patientId));
      return [migrated];
    } catch (_) {
      return const [];
    }
  }
}
