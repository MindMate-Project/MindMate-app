import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Patient location snapshot from device API or local fallback.
class PatientLocation extends Equatable {
  /// Device is treated as offline when its last report is older than this.
  static const deviceOnlineThreshold = Duration(minutes: 5);

  final double latitude;
  final double longitude;
  final String address;
  final DateTime? updatedAt;
  final bool inSafeZone;
  final String? zoneLabel;
  final String patientName;
  final bool isFallback;
  final bool isDeviceOnline;

  const PatientLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.updatedAt,
    required this.inSafeZone,
    this.zoneLabel,
    required this.patientName,
    this.isFallback = false,
    this.isDeviceOnline = true,
  });

  String get statusLabel =>
      zoneLabel ?? (inSafeZone ? 'Safe Zone' : 'Outside Zone');

  bool get isStaleDeviceData =>
      !isFallback && !isDeviceOnline && hasValidCoordinates;

  String get safeZoneStatusLabel {
    if (!inSafeZone) return 'outside safe zone';
    return zoneLabel?.trim().isNotEmpty == true
        ? zoneLabel!.trim().toLowerCase()
        : 'in safe zone';
  }

  String lastSeenLine({required bool hasSafeZones}) {
    final when = _formatLastSeen(updatedAt);
    if (hasSafeZones) {
      return 'Last seen at $when — $safeZoneStatusLabel';
    }
    return 'Last seen at $when';
  }

  String get displayInitial {
    final trimmed = patientName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  factory PatientLocation.fromApiJson(
    dynamic raw, {
    required String patientName,
  }) {
    final map = _unwrap(raw);
    final lat = _readDouble(map, const ['latitude', 'lat']);
    final lng = _readDouble(map, const ['longitude', 'lng', 'lon']);
    final address = _readString(map, const [
      'address',
      'location',
      'locationName',
      'place',
      'formattedAddress',
    ]);
    final updatedAt = _readDateTime(map, const [
      'timestamp',
      'updatedAt',
      'lastUpdated',
      'recordedAt',
      'time',
    ]);
    final inSafeZone = _readSafeZone(map);
    final zoneLabel = _readString(map, const [
      'zoneName',
      'safeZoneName',
      'zone',
      'statusLabel',
    ]);
    final isDeviceOnline = _readDeviceOnline(map, updatedAt);

    return PatientLocation(
      latitude: lat ?? 0,
      longitude: lng ?? 0,
      address: address ?? '',
      updatedAt: updatedAt,
      inSafeZone: inSafeZone,
      zoneLabel: zoneLabel?.isNotEmpty == true ? zoneLabel : null,
      patientName:
          _readString(map, const ['name', 'patientName']) ?? patientName,
      isDeviceOnline: isDeviceOnline,
    );
  }

  PatientLocation copyWith({
    double? latitude,
    double? longitude,
    String? address,
    DateTime? updatedAt,
    bool? inSafeZone,
    String? zoneLabel,
    String? patientName,
    // bool? isFallback,
    bool? isDeviceOnline,
  }) {
    return PatientLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      updatedAt: updatedAt ?? this.updatedAt,
      inSafeZone: inSafeZone ?? this.inSafeZone,
      zoneLabel: zoneLabel ?? this.zoneLabel,
      patientName: patientName ?? this.patientName,
      // isFallback: isFallback ?? this.isFallback,
      isDeviceOnline: isDeviceOnline ?? this.isDeviceOnline,
    );
  }

  String get coordinatesLabel =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  bool get hasValidCoordinates {
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude == 0 && longitude == 0) return false;
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is! Map) return {};

    final root = Map<String, dynamic>.from(raw);
    final inner = root['data'] ?? root['location'] ?? root['device'];
    final map = inner is Map
        ? Map<String, dynamic>.from(inner)
        : root;

    // Backend nests coordinates under `device` inside `data`.
    final device = map['device'];
    if (device is Map) {
      for (final entry in Map<String, dynamic>.from(device).entries) {
        map.putIfAbsent(entry.key, () => entry.value);
      }
    }

    return map;
  }

  static double? _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is num) {
        final parsed = value.toDouble();
        if (parsed.isFinite) return parsed;
        continue;
      }
      final parsed = double.tryParse(value.toString());
      if (parsed != null && parsed.isFinite) return parsed;
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  static DateTime? _readDateTime(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed.toLocal();
    }
    return null;
  }

  static bool _readSafeZone(Map<String, dynamic> map) {
    if (map['isOutsideSafeZone'] == true ||
        map['outsideSafeZone'] == true ||
        map['isOutsideHome'] == true) {
      return false;
    }
    if (map['insideHome'] == false) return false;

    for (final key in ['inSafeZone', 'isInSafeZone', 'isSafe', 'insideZone']) {
      final value = map[key];
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase();
        if (lower.contains('safe') && !lower.contains('unsafe')) return true;
        if (lower.contains('outside') || lower.contains('unsafe')) {
          return false;
        }
      }
    }

    final status = map['status']?.toString().toLowerCase();
    if (status != null) {
      if (status.contains('outside') ||
          status.contains('alert') ||
          status.contains('unsafe')) {
        return false;
      }
      if (status.contains('safe') && !status.contains('unsafe')) return true;
    }

    // Unknown until client-side geofence check runs.
    return false;
  }

  static bool _readDeviceOnline(Map<String, dynamic> map, DateTime? updatedAt) {
    for (final key in const [
      'isOnline',
      'isDeviceOnline',
      'online',
      'deviceOnline',
    ]) {
      final value = map[key];
      if (value is bool) return value;
      if (value is String) {
        final lower = value.trim().toLowerCase();
        if (lower == 'online' || lower == 'connected' || lower == 'true') {
          return true;
        }
        if (lower == 'offline' ||
            lower == 'disconnected' ||
            lower == 'false') {
          return false;
        }
      }
    }

    final status = map['status']?.toString().toLowerCase();
    if (status != null) {
      if (status.contains('offline') || status.contains('disconnected')) {
        return false;
      }
      if (status.contains('online') || status.contains('connected')) {
        return true;
      }
    }

    if (updatedAt == null) return false;
    return DateTime.now().difference(updatedAt) <= deviceOnlineThreshold;
  }

  static String _formatLastSeen(DateTime? time) {
    if (time == null) return 'unknown time';
    final now = DateTime.now();
    final diff = now.difference(time);
    final absolute = DateFormat.jm().format(time);
    if (diff.inSeconds < 60) return '$absolute (just now)';
    if (diff.inMinutes < 60) return '$absolute (${diff.inMinutes}m ago)';
    if (diff.inHours < 24) return '$absolute (${diff.inHours}h ago)';
    return absolute;
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        address,
        updatedAt,
        inSafeZone,
        zoneLabel,
        patientName,
        // isFallback,
        isDeviceOnline,
      ];
}
