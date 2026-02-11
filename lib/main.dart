import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/cubits/auth_cubit.dart';
import 'package:mindmate/services/auth_service.dart';
import 'package:mindmate/screens/splash.dart';
import 'package:mindmate/screens/auth/login.dart';
import 'package:mindmate/screens/auth/signup.dart';
import 'package:mindmate/screens/home.dart';
import 'package:mindmate/screens/auth/forgot_password.dart';
import 'package:mindmate/screens/auth/verify_code.dart';
import 'package:mindmate/screens/auth/reset_password.dart';
import 'package:mindmate/screens/auth/updated_pass.dart';
import 'package:mindmate/screens/onboarding/common/role_selection_page.dart';
import 'package:mindmate/screens/onboarding/patient/ui/patient_onboarding_screen.dart';
import 'package:mindmate/screens/onboarding/caregiver/ui/caregiver_onboarding_screen.dart';

void main() {
  runApp(
    BlocProvider(
      create: (context) => AuthCubit(AuthService()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => Splash(),
          '/roleSelection': (context) => RoleSelectionPage(),
          '/login': (context) => Login(),
          '/signup': (context) => Signup(),
          '/home': (context) => Home(),
          '/forgot_password': (context) => ForgotPasswordScreen(),
          '/updatedpass': (context) => UpdatedPass(),
          '/patient_onboarding': (_) => const PatientOnboardingScreen(),
          '/caregiver_onboarding': (_) => const CaregiverOnboardingScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/verify-code') {
            final email = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => VerifyCodeScreen(email: email),
            );
          }
          if (settings.name == '/reset-password') {
            return MaterialPageRoute(
              builder: (context) => const ResetPasswordScreen(),
              settings: settings, // Pass settings to preserve arguments
            );
          }
          return null;
        },
      ),
    ),
  );
}
