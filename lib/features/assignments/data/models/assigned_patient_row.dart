class AssignedPatientRow {
  final String patientId;
  final String name;
  final String email;
  final String? relationship;
  final DateTime? connectedAt;

  const AssignedPatientRow({
    required this.patientId,
    required this.name,
    required this.email,
    this.relationship,
    this.connectedAt,
  });

  factory AssignedPatientRow.fromJson(Map<String, dynamic> json) {
    final id = json['patientId']?.toString() ?? '';
    return AssignedPatientRow(
      patientId: id,
      name: json['name']?.toString() ?? '—',
      email: json['email']?.toString() ?? '',
      relationship: json['relationship']?.toString(),
      connectedAt: _parse(json['connectedAt']),
    );
  }

  static DateTime? _parse(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
