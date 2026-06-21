import 'dart:convert';

import 'package:mindmate/features/location/data/models/safe_zone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafeZoneService {
  static String _listKey(String patientId) => 'safe_zones_$patientId';
  static String _legacyKey(String patientId) => 'safe_zone_$patientId';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<List<SafeZone>> getSafeZones(String patientId) async {
    if (patientId.isEmpty) return const [];

    final prefs = await _ensurePrefs();
    final rawList = prefs.getString(_listKey(patientId));
    if (rawList != null && rawList.isNotEmpty) {
      return _parseList(rawList, patientId);
    }

    return _migrateLegacyZone(prefs, patientId);
  }

  Future<SafeZone> addSafeZone(SafeZone zone) async {
    final zones = await getSafeZones(zone.patientId);
    final withId = zone.id.isEmpty ? zone.copyWith(id: SafeZone.newId()) : zone;
    await _saveAll(zone.patientId, [...zones, withId]);
    return withId;
  }

  Future<SafeZone> updateSafeZone(SafeZone zone) async {
    final zones = await getSafeZones(zone.patientId);
    final index = zones.indexWhere((z) => z.id == zone.id);
    if (index < 0) throw StateError('Safe zone not found');
    final updated = [...zones]..[index] = zone;
    await _saveAll(zone.patientId, updated);
    return zone;
  }

  Future<void> removeSafeZone(String patientId, String zoneId) async {
    if (patientId.isEmpty || zoneId.isEmpty) return;
    final zones = await getSafeZones(patientId);
    await _saveAll(patientId, zones.where((z) => z.id != zoneId).toList());
  }

  Future<void> clearAllSafeZones(String patientId) async {
    if (patientId.isEmpty) return;
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
          .where((z) => z.id.isNotEmpty)
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
        id: zone.id.isEmpty ? SafeZone.newId() : zone.id,
        patientId: patientId,
      );
      await _saveAll(patientId, [migrated]);
      await prefs.remove(_legacyKey(patientId));
      return [migrated];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveAll(String patientId, List<SafeZone> zones) async {
    final prefs = await _ensurePrefs();
    final encoded = jsonEncode(zones.map((z) => z.toJson()).toList());
    await prefs.setString(_listKey(patientId), encoded);
  }
}
