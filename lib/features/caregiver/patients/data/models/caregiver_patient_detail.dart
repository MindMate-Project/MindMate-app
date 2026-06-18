import 'package:intl/intl.dart';
import 'package:mindmate/features/assignments/data/models/caregiver_relationship.dart';

/// Structured health record from `medicalNotes` on the patient detail API.
class PatientMedicalNotes {
  final String? diagnosis;
  final String? stage;
  final List<String> chronicDiseases;
  final List<String> allergies;
  final List<String> currentMedication;
  final String? freeText;

  const PatientMedicalNotes({
    this.diagnosis,
    this.stage,
    this.chronicDiseases = const [],
    this.allergies = const [],
    this.currentMedication = const [],
    this.freeText,
  });

  bool get isEmpty =>
      (diagnosis?.trim().isEmpty ?? true) &&
      (stage?.trim().isEmpty ?? true) &&
      chronicDiseases.isEmpty &&
      allergies.isEmpty &&
      currentMedication.isEmpty &&
      (freeText?.trim().isEmpty ?? true);

  factory PatientMedicalNotes.fromJson(dynamic value) {
    if (value == null) return const PatientMedicalNotes();
    if (value is String) {
      final trimmed = value.trim();
      return PatientMedicalNotes(
        freeText: trimmed.isEmpty ? null : trimmed,
      );
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return PatientMedicalNotes(
        diagnosis: _stringOrNull(map['diagnosis']),
        stage: _stringOrNull(map['stage']),
        chronicDiseases: _parseStringList(
          map['chronicDiseases'] ?? map['chronicDisease'],
        ),
        allergies: _parseStringList(map['allergies']),
        currentMedication: _parseStringList(
          map['currentMedication'] ??
              map['currentMedications'] ??
              map['medications'],
        ),
      );
    }
    return const PatientMedicalNotes();
  }

  static String? _stringOrNull(dynamic value) {
    final s = value?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  String formatList(List<String> items) =>
      items.isEmpty ? '—' : items.join(', ');

  Map<String, dynamic> toJson() => {
        if (diagnosis != null && diagnosis!.trim().isNotEmpty)
          'diagnosis': diagnosis!.trim(),
        if (stage != null && stage!.trim().isNotEmpty) 'stage': stage!.trim(),
        'chronicDiseases': chronicDiseases,
        'allergies': allergies,
        'currentMedication': currentMedication,
      };

  static List<String> parseCommaSeparated(String text) => text
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

/// IoT device summary returned with the patient detail payload.
class PatientDeviceInfo {
  final String? deviceId;
  final DateTime? timestamp;

  const PatientDeviceInfo({this.deviceId, this.timestamp});

  bool get hasDevice => (deviceId?.trim().isNotEmpty ?? false);

  factory PatientDeviceInfo.fromJson(dynamic value) {
    if (value is! Map) return const PatientDeviceInfo();
    final map = Map<String, dynamic>.from(value);
    return PatientDeviceInfo(
      deviceId: map['deviceId']?.toString(),
      timestamp: _parseDate(map['timestamp']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

/// Full patient record returned by `GET /api/caregiver/patients/:patientId`.
class CaregiverPatientDetail {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? gender;
  final String? relationship;
  final DateTime? dateOfBirth;
  final DateTime? connectedAt;
  final PatientMedicalNotes medicalNotes;
  final PatientDeviceInfo device;
  final String? photoUrl;

  const CaregiverPatientDetail({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    this.address,
    this.gender,
    this.relationship,
    this.dateOfBirth,
    this.connectedAt,
    this.medicalNotes = const PatientMedicalNotes(),
    this.device = const PatientDeviceInfo(),
    this.photoUrl,
  });

  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }

  String? get formattedDateOfBirth {
    final dob = dateOfBirth;
    if (dob == null) return null;
    return DateFormat('d MMM yyyy').format(dob.toLocal());
  }

  String? get formattedConnectedAt {
    final at = connectedAt;
    if (at == null) return null;
    return DateFormat('d MMM yyyy').format(at.toLocal());
  }

  String? get formattedDeviceLastSeen {
    final at = device.timestamp;
    if (at == null) return null;
    return DateFormat('d MMM yyyy, h:mm a').format(at.toLocal());
  }

  String get relationshipLabel {
    final parsed = CaregiverRelationship.tryParseApi(relationship);
    if (parsed != null) return parsed.label;
    final raw = relationship?.trim() ?? '';
    if (raw.isEmpty) return '—';
    return raw[0].toUpperCase() + raw.substring(1).replaceAll('_', ' ');
  }

  factory CaregiverPatientDetail.fromJson(Map<String, dynamic> json) {
    return CaregiverPatientDetail(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          json['patientId']?.toString() ??
          '',
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phoneNumber:
          json['phoneNumber']?.toString() ?? json['phone']?.toString(),
      address: json['address']?.toString(),
      gender: _formatGender(json['gender']?.toString()),
      relationship: json['relationship']?.toString(),
      dateOfBirth: _parseDate(json['dateOfBirth']),
      connectedAt: _parseDate(json['connectedAt']),
      medicalNotes: PatientMedicalNotes.fromJson(json['medicalNotes']),
      device: PatientDeviceInfo.fromJson(json['device']),
      photoUrl: _firstNonEmpty(json, const [
        'photoUrl',
        'photo',
        'avatar',
        'avatarUrl',
        'profileImage',
        'profilePicture',
        'image',
        'picture',
      ]),
    );
  }

  static String? _formatGender(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final lower = raw.trim().toLowerCase();
    if (lower == 'male' || lower == 'female') {
      return lower[0].toUpperCase() + lower.substring(1);
    }
    return raw.trim();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String? _firstNonEmpty(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        final s = value.toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }
}
