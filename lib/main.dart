import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/patient/home/presentation/screens/home_screen.dart';
import 'package:mindmate/features/caregiver/presentation/screens/home_screen.dart'
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
// import 'package:mindmate/features/patient/profile/presentation/screens/caregivers.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/reminders_screen.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/patient_profile.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/edit_profile_screen.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/notifications_screen.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:mindmate/core/utils/responsive.dart';
import 'package:mindmate/features/memory/presentation/screens/memory_screen.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_cubit.dart';
import 'package:mindmate/features/memory/data/services/memory_service.dart';
import 'package:mindmate/features/patient/profile/presentation/cubit/profile_cubit.dart';
import 'package:mindmate/features/patient/profile/data/services/profile_service.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit(AuthService())),
        BlocProvider(create: (context) => MemoryCubit(MemoryService())),
        BlocProvider(create: (context) => ProfileCubit(ProfileService())),
        BlocProvider(create: (context) => RemindersCubit(RemindersService())),
      ],
      
      child: Builder(
        builder: (context) {
          Responsive.init(context);
          return MaterialApp(
            debugShowCheckedModeBanner: false,
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
              '/patient_reminders': (context) => const RemindersScreen(),
              '/profile': (context) => const PatientProfileScreen(),
              '/edit_profile': (context) => const EditProfileScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              // '/my_caregivers' : (context) => const MyCaregivers(),
              '/privacy_policy': (context) => const PrivacyPolicyScreen(),
              // '/medical_information': (context) =>
              //     const MedicalInformationScreen(),
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
                final email = settings.arguments is String
                    ? settings.arguments as String
                    : (settings.arguments as Map<String, String>?)?['email'];
                return MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(email: email),
                );
              }
              return null;
            },
          );
        },
      ),
    ),
  );
}
