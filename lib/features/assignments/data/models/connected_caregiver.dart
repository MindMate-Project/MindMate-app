/// A caregiver connected to the signed-in patient, as returned by
/// `GET /api/patient/caregivers` (name + phone are used to let the patient
/// quickly call for help, e.g. from the face-recognition "not found" screen).
class ConnectedCaregiver {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;

  const ConnectedCaregiver({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
  });

  bool get hasPhone => (phoneNumber ?? '').trim().isNotEmpty;

  /// First word of the name, for compact labels like "Call samir".
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'caregiver';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  factory ConnectedCaregiver.fromJson(Map<String, dynamic> json) {
    return ConnectedCaregiver(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      email: json['email']?.toString(),
      phoneNumber:
          json['phoneNumber']?.toString() ?? json['phone']?.toString(),
    );
  }
}
