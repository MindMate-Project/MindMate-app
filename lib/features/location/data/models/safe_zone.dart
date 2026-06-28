import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mindmate/features/location/data/models/patient_location.dart';

/// Caregiver-defined safe area synced with `PATCH /api/device/safe-zone/:patientId`.
class SafeZone extends Equatable {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String name;

  const SafeZone({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200,
    this.name = 'Home',
  });

  String get displayName => name.trim().isEmpty ? 'Safe Zone' : name.trim();

  bool get hasValidCenter =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      !(latitude == 0 && longitude == 0);

  bool get hasValidRadius => radiusMeters.isFinite && radiusMeters > 0;

  bool get isRenderable => hasValidCenter && hasValidRadius;

  bool contains(double lat, double lng) {
    final distance = Geolocator.distanceBetween(
      latitude,
      longitude,
      lat,
      lng,
    );
    return distance <= radiusMeters;
  }

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    return SafeZone(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      latitude: _finiteDouble(json['latitude']) ?? 0,
      longitude: _finiteDouble(json['longitude']) ?? 0,
      radiusMeters: _finiteDouble(json['radiusMeters']) ?? 200,
      name: json['name']?.toString() ?? 'Home',
    );
  }

  /// Parses `homeLocation` from device/location or safe-zone API responses.
  static SafeZone? fromHomeLocation({
    required String patientId,
    required dynamic raw,
    String name = 'Home',
  }) {
    return _findHomeLocation(raw, patientId: patientId, name: name);
  }

  static SafeZone? _findHomeLocation(
    dynamic raw, {
    required String patientId,
    required String name,
    int depth = 0,
  }) {
    if (raw == null || depth > 6) return null;
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    for (final key in const [
      'homeLocation',
      'home_location',
      'safeZone',
      'safe_zone',
      'geofence',
    ]) {
      final parsed = _parseHomeMap(map[key], patientId: patientId, name: name);
      if (parsed != null) return parsed;
    }

    final data = map['data'];
    if (data != null) {
      final nested = _findHomeLocation(
        data,
        patientId: patientId,
        name: name,
        depth: depth + 1,
      );
      if (nested != null) return nested;
    }

    for (final entry in map.entries) {
      if (entry.key == 'data') continue;
      final nested = _findHomeLocation(
        entry.value,
        patientId: patientId,
        name: name,
        depth: depth + 1,
      );
      if (nested != null) return nested;
    }
    return null;
  }

  static SafeZone? _parseHomeMap(
    dynamic raw, {
    required String patientId,
    required String name,
  }) {
    if (raw is! Map) return null;
    final home = Map<String, dynamic>.from(raw);
    if (home.isEmpty) return null;

    final lat = _readDouble(home, const ['lat', 'latitude']);
    final lng = _readDouble(home, const ['lng', 'longitude', 'lon']);
    if (lat == null || lng == null) return null;

    return SafeZone(
      id: patientId,
      patientId: patientId,
      latitude: lat,
      longitude: lng,
      radiusMeters:
          _readDouble(home, const ['radiusMeters', 'radius', 'radius_meters']) ??
              200,
      name: home['name']?.toString().trim().isNotEmpty == true
          ? home['name'].toString()
          : name,
    );
  }

  /// Client-side check: is [location] inside any of [zones]?
  static PatientLocation applyZoneStatus({
    required PatientLocation location,
    required List<SafeZone> zones,
  }) {
    if (zones.isEmpty || !location.hasValidCoordinates) return location;

    final match = locate(zones, location.latitude, location.longitude);
    return location.copyWith(
      inSafeZone: match.inAny,
      zoneLabel: match.inAny
          ? match.zone!.displayName
          : 'Outside safe zones',
    );
  }

  static double? _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) {
        final parsed = value.toDouble();
        if (parsed.isFinite) return parsed;
        continue;
      }
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null && parsed.isFinite) return parsed;
    }
    return null;
  }

  static double? _finiteDouble(dynamic value) {
    if (value is! num) return null;
    final parsed = value.toDouble();
    return parsed.isFinite ? parsed : null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'name': name,
      };

  SafeZone copyWith({
    String? id,
    String? patientId,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? name,
  }) {
    return SafeZone(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      name: name ?? this.name,
    );
  }

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Whether [lat,lng] falls inside any zone; returns the first match.
  static ({bool inAny, SafeZone? zone}) locate(
    List<SafeZone> zones,
    double lat,
    double lng,
  ) {
    for (final zone in zones) {
      if (zone.contains(lat, lng)) {
        return (inAny: true, zone: zone);
      }
    }
    return (inAny: false, zone: null);
  }

  @override
  List<Object?> get props =>
      [id, patientId, latitude, longitude, radiusMeters, name];
}
