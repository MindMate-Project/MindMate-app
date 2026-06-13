import 'secrets.dart';

class ApiConfig {
  static const String baseUrl = 'https://alzaheimer-backend.onrender.com';
  static const String apiKey = Secrets.apiKey;

  // Auth endpoints are called as relative paths by AuthService (e.g.
  // '/api/auth/login'), so no per-endpoint constants are kept here.

  // Face Recognition endpoints
  static const String faceBase = '$baseUrl/api/face';
  static const String identifyFaceEndpoint = '$faceBase/patient/identify-face';
  // Register a known person the patient should recognize (caregiver action).
  static const String registerFaceEndpoint = '$faceBase/patient/register-face';

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
