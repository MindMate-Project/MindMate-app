/// Central route path constants for the app.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const roleSelection = '/roleSelection';
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';
  static const forgotPassword = '/forgot_password';
  static const verifyCode = '/verify-code';
  static const resetPassword = '/reset-password';
  static const updatedPass = '/updatedpass';
  static const patientHome = '/patient_home';
  static const caregiverHome = '/caregiver_home';
  static const memory = '/memory';
  static const memoryAdd = '/memory/add';
  static const memoryDrill = '/memory/drill';
  static const patientReminders = '/patient_reminders';
  static const profile = '/profile';
  static const editProfile = '/edit_profile';
  static const notifications = '/notifications';
  static const patientCaregivers = '/patient_caregivers';
  static const patientAssignmentInbox = '/patient_assignment_inbox';
  static const caregiverNotifications = '/caregiver_notifications';
  static const caregiverPatients = '/caregiver_patients';
  static const location = '/location';
  static const safeZones = '/location/safe-zones';
  static const privacyPolicy = '/privacy_policy';

  static String reminderDetail(String reminderId) => '/reminder/$reminderId';
}
