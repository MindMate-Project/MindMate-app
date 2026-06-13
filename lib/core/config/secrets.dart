class Secrets {
  /// Optional API key, supplied at build time:
  ///   flutter run --dart-define=MINDMATE_API_KEY=...
  ///
  /// Never hard-code real tokens/secrets in this file — it is committed to the
  /// repository. (A real, expired user JWT used to live here and was shipped in
  /// the APK; rotate the backend JWT_SECRET_KEY so any leaked token is void.)
  static const String apiKey =
      String.fromEnvironment('MINDMATE_API_KEY', defaultValue: '');
}
