import 'package:mindmate/features/assignments/data/models/caregiver_relationship.dart';

/// A caregiver connected to the signed-in patient, as returned by
/// `GET /api/patient/caregivers` and `GET /api/patient/caregivers/:caregiverId`.
class ConnectedCaregiver {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? relationship;
  final DateTime? connectedAt;
  final String? photoUrl;
  final String? address;
  final String? gender;

  const ConnectedCaregiver({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.relationship,
    this.connectedAt,
    this.photoUrl,
    this.address,
    this.gender,
  });

  bool get hasPhone => (phoneNumber ?? '').trim().isNotEmpty;

  String get relationshipLabel {
    final rel = CaregiverRelationship.tryParseApi(relationship);
    if (rel != null) return rel.label;
    final raw = relationship?.trim() ?? '';
    return raw.isEmpty ? '—' : raw;
  }

  String get genderLabel {
    final g = gender?.trim().toLowerCase() ?? '';
    if (g.isEmpty) return '—';
    if (g.startsWith('m')) return 'Male';
    if (g.startsWith('f')) return 'Female';
    return gender!.trim();
  }

  /// First word of the name, for compact labels like "Call samir".
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'caregiver';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  /// List row from `GET /api/patient/caregivers`. Pass [patientId] when the
  /// payload is a full caregiver document (relationship lives in `patients[]`).
  factory ConnectedCaregiver.fromJson(
    Map<String, dynamic> json, {
    String? patientId,
  }) {
    final hasCaregiverDoc =
        json['_id'] != null || json['id'] != null || json['caregiverId'] != null;
    if (hasCaregiverDoc &&
        patientId != null &&
        patientId.isNotEmpty &&
        json['patients'] is List) {
      return ConnectedCaregiver.fromDetailJson(json, patientId: patientId);
    }

    final nested = json['caregiver'];
    final Map<String, dynamic> source = nested is Map
        ? Map<String, dynamic>.from(nested)
        : json;

    final id = json['caregiverId']?.toString() ??
        source['_id']?.toString() ??
        source['id']?.toString() ??
        '';

    final link = patientId != null && patientId.isNotEmpty
        ? _linkForPatient(json['patients'] ?? source['patients'], patientId)
        : null;

    return ConnectedCaregiver(
      id: id,
      name: (source['name'] ?? json['name'] ?? '').toString(),
      email: source['email']?.toString() ?? json['email']?.toString(),
      phoneNumber: source['phoneNumber']?.toString() ??
          source['phone']?.toString() ??
          json['phoneNumber']?.toString() ??
          json['phone']?.toString(),
      relationship: json['relationship']?.toString() ??
          source['relationship']?.toString() ??
          link?.relationship,
      connectedAt: _parseDate(
        json['connectedAt'] ?? source['connectedAt'] ?? link?.connectedAt,
      ),
      photoUrl: json['profilePicture']?.toString() ??
          source['profilePicture']?.toString() ??
          json['photoUrl']?.toString() ??
          source['photoUrl']?.toString(),
      address: source['address']?.toString() ?? json['address']?.toString(),
      gender: source['gender']?.toString() ?? json['gender']?.toString(),
    );
  }

  /// Detail payload from `GET /api/patient/caregivers/:caregiverId`.
  /// Relationship and connected date live under `patients[]` for the
  /// signed-in patient — pass [patientId] to resolve the correct link.
  factory ConnectedCaregiver.fromDetailJson(
    Map<String, dynamic> json, {
    required String patientId,
  }) {
    final link = _linkForPatient(json['patients'], patientId);

    return ConnectedCaregiver(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString() ?? json['phone']?.toString(),
      relationship: link?.relationship,
      connectedAt: link?.connectedAt,
      photoUrl:
          json['profilePicture']?.toString() ?? json['photoUrl']?.toString(),
      address: json['address']?.toString(),
      gender: json['gender']?.toString(),
    );
  }

  static ({String? relationship, DateTime? connectedAt})? _linkForPatient(
    dynamic patients,
    String patientId,
  ) {
    if (patients is! List) return null;
    for (final entry in patients) {
      if (entry is! Map) continue;
      final pid = entry['patient']?.toString();
      if (pid == patientId) {
        return (
          relationship: entry['relationship']?.toString(),
          connectedAt: _parseDate(entry['connectedAt']),
        );
      }
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
