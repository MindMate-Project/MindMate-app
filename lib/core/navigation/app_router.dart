import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mindmate/core/navigation/app_navigation.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/assignments/presentation/cubit/patient_assignment_requests_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/login_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/signup_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/splash_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/updated_pass_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:mindmate/features/caregiver/home/presentation/screens/caregiver_home_screen.dart'
    as caregiver;
import 'package:mindmate/features/caregiver/patients/presentation/screens/caregiver_patients_screen.dart';
import 'package:mindmate/features/caregiver/profile/presentation/screens/caregiver_notifications_screen.dart';
import 'package:mindmate/features/caregiver/profile/presentation/screens/caregiver_profile_screen.dart';
import 'package:mindmate/features/location/presentation/screens/location_tracking_screen.dart';
import 'package:mindmate/features/location/presentation/screens/safe_zones_screen.dart';
import 'package:mindmate/features/memory/presentation/screens/add_memory_screen.dart';
import 'package:mindmate/features/memory/presentation/screens/memory_drill_screen.dart';
import 'package:mindmate/features/memory/presentation/screens/memory_screen.dart';
import 'package:mindmate/features/onboarding/presentation/screens/onboarding/common/onboarding_item.dart';
import 'package:mindmate/features/onboarding/presentation/screens/onboarding/common/onboarding_screen.dart';
import 'package:mindmate/features/onboarding/presentation/screens/onboarding/common/role_selection_page.dart';
import 'package:mindmate/features/patient/home/presentation/screens/home_screen.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/patient_assignment_inbox_screen.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/patient_caregivers_screen.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/patient_notifications_screen.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/patient_profile_screen.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/reminder_detail_screen.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/reminders_screen.dart';
import 'package:mindmate/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:mindmate/features/profile/presentation/screens/privacy_policy_screen.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Coming soon')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This feature is coming soon.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const Splash(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (context, state) => const RoleSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const Login(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const Signup(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) {
          final items = state.extra! as List<OnboardingItem>;
          return OnboardingScreen(items: items);
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyCode,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return VerifyCodeScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) {
          final args = state.extra;
          String? email;
          String? code;
          if (args is String) {
            email = args;
          } else if (args is Map) {
            email = args['email'] as String?;
            code = args['code'] as String?;
          }
          return ResetPasswordScreen(email: email, code: code);
        },
      ),
      GoRoute(
        path: AppRoutes.updatedPass,
        builder: (context, state) => const UpdatedPass(),
      ),
      GoRoute(
        path: AppRoutes.patientHome,
        builder: (context, state) => const PatientHomePage(),
      ),
      GoRoute(
        path: AppRoutes.caregiverHome,
        builder: (context, state) => const caregiver.CaregiverHomePage(),
      ),
      GoRoute(
        path: AppRoutes.memory,
        builder: (context, state) => const MemoryScreen(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddMemoryScreen(),
          ),
          GoRoute(
            path: 'drill',
            builder: (context, state) {
              final extra = state.extra;
              final memoryId = extra is Map
                  ? extra['memoryId'] as String?
                  : extra is String
                  ? extra
                  : null;
              return MemoryDrillScreen(memoryId: memoryId);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.patientReminders,
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/reminder/:reminderId',
        builder: (context, state) {
          final reminderId = state.pathParameters['reminderId']!;
          return ReminderDetailScreen(reminderId: reminderId);
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final isCaregiver =
                authState is AuthSuccess && authState.user.isCaregiver;
            return isCaregiver
                ? const CaregiverProfileScreen()
                : const PatientProfileScreen();
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final isCaregiver =
                authState is AuthSuccess && authState.user.isCaregiver;
            return isCaregiver
                ? const CaregiverNotificationsScreen()
                : const PatientNotificationsScreen();
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.patientCaregivers,
        builder: (context, state) => const PatientCaregiversScreen(),
      ),
      GoRoute(
        path: AppRoutes.patientAssignmentInbox,
        builder: (context, state) => BlocProvider(
          create: (_) => PatientAssignmentRequestsCubit(AssignmentService()),
          child: const PatientAssignmentInboxScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.caregiverNotifications,
        builder: (context, state) => const CaregiverNotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.caregiverPatients,
        builder: (context, state) => const CaregiverPatientsScreen(),
      ),
      GoRoute(
        path: AppRoutes.location,
        builder: (context, state) => const LocationTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.safeZones,
        builder: (context, state) {
          final tabIndex = state.extra is int ? state.extra as int : 0;
          return SafeZonesScreen(initialTabIndex: tabIndex);
        },
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
    ],
  );
}
