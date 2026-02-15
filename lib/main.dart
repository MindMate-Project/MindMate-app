import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/cubits/auth_cubit.dart';
import 'package:mindmate/screens/home_screen.dart';
import 'package:mindmate/services/auth_service.dart';
import 'package:mindmate/screens/splash.dart';
import 'package:mindmate/screens/auth/login.dart';
import 'package:mindmate/screens/auth/signup.dart';
import 'package:mindmate/screens/auth/forgot_password.dart';
import 'package:mindmate/screens/auth/verify_code.dart';
import 'package:mindmate/screens/auth/reset_password.dart';
import 'package:mindmate/screens/auth/updated_pass.dart';
import 'package:mindmate/screens/onboarding/common/role_selection_page.dart';
import 'package:mindmate/screens/onboarding/common/onboarding_screen.dart';
import 'package:mindmate/screens/onboarding/common/onboarding_item.dart';

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
          '/home': (context) => HomePage(),
          '/forgot_password': (context) => ForgotPasswordScreen(),
          '/updatedpass': (context) => UpdatedPass(),
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
      ),
    ),
  );
}
