class ApiConfig {
  static const String baseUrl = 'https://alzaheimer-backend.onrender.com';

  // Auth endpoints
  static const String authBase = '$baseUrl/api/auth';
  static const String registerEndpoint = '$authBase/register';
  static const String loginEndpoint = '$authBase/login';
  static const String forgotPasswordEndpoint = '$authBase/forgot-password';
  static const String resetPasswordEndpoint = '$authBase/reset-password';
  static const String verifyResetPasswordEndpoint = '$authBase/verify-reset-password';
  static const String verifyEndpoint = '$authBase/verify';
}
