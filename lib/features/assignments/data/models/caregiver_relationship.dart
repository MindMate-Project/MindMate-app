/// Values accepted by `POST /api/caregiver/patients/assignment-request`.
enum CaregiverRelationship {
  son('son', 'Son'),
  daughter('daughter', 'Daughter'),
  sibling('sibling', 'Sibling'),
  medicalStaff('medical_staff', 'Medical staff'),
  other('other', 'Other');

  const CaregiverRelationship(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CaregiverRelationship? tryParseApi(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final r in CaregiverRelationship.values) {
      if (r.apiValue == raw) return r;
    }
    return null;
  }
}
