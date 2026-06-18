/// Extracts the first word from a full name for greetings and short labels.
String? firstNameOf(String? fullName) {
  final trimmed = fullName?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return trimmed.split(RegExp(r'\s+')).first;
}
