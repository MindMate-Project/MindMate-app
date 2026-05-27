import 'secrets.dart';

class ApiConfig {
  static const String baseUrl = 'https://alzaheimer-backend.onrender.com';
  static const String apiKey = Secrets.apiKey;

  // Auth endpoints
  static const String authBase = '$baseUrl/api/auth';
  static const String registerEndpoint = '$authBase/register';
  static const String loginEndpoint = '$authBase/login';
  static const String forgotPasswordEndpoint = '$authBase/forgot-password';
  static const String resetPasswordEndpoint = '$authBase/reset-password';
  static const String verifyResetPasswordEndpoint = '$authBase/verify-reset-password';
  static const String verifyEndpoint = '$authBase/verify';

  // Face Recognition endpoints
  static const String faceBase = '$baseUrl/api/face';
  static const String identifyFaceEndpoint = '$faceBase/patient/identify-face';

  // Memory endpoints
  static const String memoryBase = '$baseUrl/api/memories';
  // GET    /api/memories/patient/:patientId  — list a patient's memories
  // POST   /api/memories                     — create a new memory (multipart for media)
  // PUT    /api/memories/:id                 — update text fields only (caregiver/admin)
  // DELETE /api/memories/:id                 — delete memory + Cloudinary asset (caregiver/admin)
  static const String createMemoryEndpoint = '/api/memories';
  static String memoriesForPatientEndpoint(String patientId) =>
      '/api/memories/patient/$patientId';
  static String updateMemoryEndpoint(String id) => '/api/memories/$id';
  static String deleteMemoryEndpoint(String id) => '/api/memories/$id';
}
