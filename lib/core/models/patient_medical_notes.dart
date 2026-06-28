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
