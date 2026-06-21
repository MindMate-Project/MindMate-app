import 'secrets.dart';

class ApiConfig {
  static const String baseUrl = 'https://alzaheimer-backend.onrender.com';
  static const String apiKey = Secrets.apiKey;

  // Auth endpoints are called as relative paths by AuthService (e.g.
  // '/api/auth/login'), so no per-endpoint constants are kept here.

  // Reminders endpoints
  static const String createReminderEndpoint = '/api/reminders';
  static String patientRemindersEndpoint(String patientId) =>
      '/api/reminders/patient/$patientId';
  static String reminderByIdEndpoint(String reminderId) =>
      '/api/reminders/$reminderId';

  // Face Recognition endpoints
  static const String identifyFaceEndpoint = '/api/face/patient/identify-face';
  // Register a known person the patient should recognize (caregiver action).
  static const String registerFaceEndpoint = '/api/face/patient/register-face';

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

  // Location endpoints
  static String deviceLocationEndpoint(String patientId) =>
      '/api/device/location/$patientId';

  // Alert endpoints
  static const String createAlertEndpoint = '/api/alerts';
  static String patientAlertsEndpoint(String patientId) =>
      '/api/alerts/patient/$patientId';
  static String alertByIdEndpoint(String alertId) => '/api/alerts/$alertId';
}
