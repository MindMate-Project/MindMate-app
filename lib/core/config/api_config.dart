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
  static String acknowledgeReminderEndpoint(String reminderId) =>
      '/api/reminders/$reminderId/acknowledge';
  static String deleteReminderSeriesEndpoint(String groupId) =>
      '/api/reminders/series?groupId=$groupId';

  // Face — patientId omitted for patient self-registration; required for caregiver.
  static const String identifyFaceEndpoint = '/api/face/patient/identify-face';
  static const String registerKnownPersonEndpoint =
      '/api/face/patient/register-face';
  static const String addFacePhotosEndpoint = '/api/face/patient/add-photos';

  // Memory endpoints
  static const String memoryBase = '$baseUrl/api/memories';
  static const String createMemoryEndpoint = '/api/memories';
  static String memoriesForPatientEndpoint(String patientId) =>
      '/api/memories/patient/$patientId';
  static String memoryByIdEndpoint(String id) => '/api/memories/$id';
  static String updateMemoryEndpoint(String id) => '/api/memories/$id';
  static String deleteMemoryEndpoint(String id) => '/api/memories/$id';
  static const String searchMemoriesEndpoint = '/api/memories/search';

  // Device endpoints
  static const String assignDeviceEndpoint = '/api/device/assign-device';
  static String deviceLocationEndpoint(String patientId) =>
      '/api/device/location/$patientId';
  static String deviceSafeZoneEndpoint(String patientId) =>
      '/api/device/safe-zone/$patientId';
  static String removeDeviceEndpoint(String patientId) =>
      '/api/device/remove/$patientId';

  // Alert endpoints
  static const String createAlertEndpoint = '/api/alerts';
  static String patientAlertsEndpoint(String patientId) =>
      '/api/alerts/patient/$patientId';
  static String alertByIdEndpoint(String alertId) => '/api/alerts/$alertId';
  static String deleteAlertEndpoint(String alertId) => '/api/alerts/$alertId';
}
