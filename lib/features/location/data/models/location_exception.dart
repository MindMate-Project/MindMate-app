class LocationException implements Exception {
  const LocationException(this.message, {this.isRecoverable = true});

  final String message;
  final bool isRecoverable;

  @override
  String toString() => message;
}
