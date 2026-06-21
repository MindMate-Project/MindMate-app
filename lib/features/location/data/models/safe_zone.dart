import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

/// Caregiver-defined safe area stored locally per patient (no backend API).
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
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 200,
      name: json['name']?.toString() ?? 'Home',
    );
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
