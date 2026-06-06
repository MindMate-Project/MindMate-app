import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/patient/home/presentation/screens/home_screen.dart';
import 'package:mindmate/features/caregiver/home/presentation/screens/caregiver_home_screen.dart'
    as caregiver;
import 'package:mindmate/features/auth/data/services/auth_service.dart';
import 'package:mindmate/features/auth/presentation/screens/splash_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/login_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/signup_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:mindmate/features/auth/presentation/screens/updated_pass_screen.dart';
import 'package:mindmate/features/onboarding/presentation/screens/onboarding/common/role_selection_page.dart';
import 'package:mindmate/features/onboarding/presentation/screens/onboarding/common/onboarding_screen.dart';
import 'package:mindmate/features/onboarding/presentation/screens/onboarding/common/onboarding_item.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/reminders_screen.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/reminder_detail_screen.dart';
import 'package:mindmate/core/navigation/app_navigation.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/patient_profile.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/edit_profile_screen.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/notifications_screen.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/patient_assignment_inbox_screen.dart';
import 'package:mindmate/features/caregiver/home/presentation/screens/caregiver_notifications_screen.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/assignments/presentation/cubit/patient_assignment_requests_cubit.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:mindmate/core/utils/responsive.dart';
import 'package:mindmate/features/memory/presentation/screens/memory_screen.dart';
import 'package:mindmate/features/memory/presentation/screens/add_memory_screen.dart';
import 'package:mindmate/features/memory/presentation/screens/memory_drill_screen.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_cubit.dart';
import 'package:mindmate/features/memory/data/services/memory_service.dart';
import 'package:mindmate/features/memory/data/services/memory_training_service.dart';
import 'package:mindmate/features/patient/profile/presentation/cubit/profile_cubit.dart';
import 'package:mindmate/features/patient/profile/data/services/profile_service.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await MemoryTrainingService.instance.init(
    onTap: (memoryId) {
      rootNavigatorKey.currentState?.pushNamed(
        '/memory/drill',
        arguments: memoryId == null ? null : {'memoryId': memoryId},
      );
    },
    onReminderTap: (reminderId) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ReminderDetailScreen(reminderId: reminderId),
        ),
      );
    },
    onReminderAlarm: showReminderAlarm,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit(AuthService(), ProfileService())),
        BlocProvider(create: (context) => MemoryCubit(MemoryService())),
        BlocProvider(create: (context) => ProfileCubit(ProfileService())),
        BlocProvider(create: (context) => RemindersCubit(RemindersService())),
      ],

      child: Builder(
        builder: (context) {
          Responsive.init(context);
          final baseTheme = ThemeData.light();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: rootNavigatorKey,
            theme: baseTheme.copyWith(
              textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme),
              primaryTextTheme:
                  GoogleFonts.cairoTextTheme(baseTheme.primaryTextTheme),
            ),
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const Splash(),
              '/roleSelection': (context) => const RoleSelectionPage(),
              '/login': (context) => const Login(),
              '/signup': (context) => const Signup(),
              '/patient_home': (context) => const PatientHomePage(),
              '/caregiver_home': (context) =>
                  const caregiver.CaregiverHomePage(),
              '/forgot_password': (context) => const ForgotPasswordScreen(),
              '/updatedpass': (context) => const UpdatedPass(),
              '/memory': (context) => const MemoryScreen(),
              '/memory/add': (context) => const AddMemoryScreen(),
              '/memory/drill': (context) => const MemoryDrillScreen(),
              '/patient_reminders': (context) => const RemindersScreen(),
              '/profile': (context) => const PatientProfileScreen(),
              '/edit_profile': (context) => const EditProfileScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/patient_assignment_inbox': (context) => BlocProvider(
                    create: (_) => PatientAssignmentRequestsCubit(AssignmentService()),
                    child: const PatientAssignmentInboxScreen(),
                  ),
              '/caregiver_notifications': (context) => const CaregiverNotificationsScreen(),
              '/privacy_policy': (context) => const PrivacyPolicyScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/onboarding') {
                final items = settings.arguments as List<OnboardingItem>;
                return MaterialPageRoute(
                  builder: (_) => OnboardingScreen(items: items),
                );
              }
              if (settings.name == '/verify-code') {
                final email = settings.arguments as String;
                return MaterialPageRoute(
                  builder: (context) => VerifyCodeScreen(email: email),
                );
              }
              if (settings.name == '/reset-password') {
                final args = settings.arguments;
                String? email;
                String? code;
                if (args is String) {
                  email = args;
                } else if (args is Map) {
                  email = args['email'] as String?;
                  code = args['code'] as String?;
                }
                return MaterialPageRoute(
                  builder: (context) =>
                      ResetPasswordScreen(email: email, code: code),
                );
              }
              return null;
            },
            // Fallback so an unregistered route degrades gracefully instead of
            // throwing (e.g. features whose screens don't exist yet).
            onUnknownRoute: (settings) => MaterialPageRoute<void>(
              builder: (_) => Scaffold(
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
            ),
          );
        },
      ),
    ),
  );
}
