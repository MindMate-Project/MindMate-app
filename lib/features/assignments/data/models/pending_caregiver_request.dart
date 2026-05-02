import 'package:mindmate/features/assignments/data/models/caregiver_relationship.dart';

class PendingCaregiverRequest {
  final String caregiverId;
  final String caregiverName;
  final String? caregiverEmail;
  final String? caregiverPhone;
  final CaregiverRelationship? relationship;
  final DateTime? requestedAt;

  const PendingCaregiverRequest({
    required this.caregiverId,
    required this.caregiverName,
    this.caregiverEmail,
    this.caregiverPhone,
    this.relationship,
    this.requestedAt,
  });

  static PendingCaregiverRequest? tryParse(Map<String, dynamic> json) {
    final caregiverRaw = json['caregiver'];
    final id = _extractCaregiverId(caregiverRaw);
    if (id == null || id.isEmpty) return null;

    final name = _extractCaregiverName(caregiverRaw) ?? 'Caregiver';
    final email = _extractString(caregiverRaw is Map ? caregiverRaw['email'] : null);
    final phone = _extractString(
      caregiverRaw is Map ? (caregiverRaw['phoneNumber'] ?? caregiverRaw['phone']) : null,
    );

    final rel = CaregiverRelationship.tryParseApi(json['relationship']?.toString());
    final requestedAt = _parseDate(json['requestedAt']);

    return PendingCaregiverRequest(
      caregiverId: id,
      caregiverName: name,
      caregiverEmail: email,
      caregiverPhone: phone,
      relationship: rel,
      requestedAt: requestedAt,
    );
  }

  static String? _extractCaregiverId(dynamic caregiver) {
    if (caregiver is Map) {
      final id = caregiver['_id'] ?? caregiver['id'];
      return id?.toString();
    }
    if (caregiver != null) return caregiver.toString();
    return null;
  }

  static String? _extractCaregiverName(dynamic caregiver) {
    if (caregiver is Map) {
      return caregiver['name']?.toString();
    }
    return null;
  }

  static String? _extractString(dynamic v) {
    final s = v?.toString();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
