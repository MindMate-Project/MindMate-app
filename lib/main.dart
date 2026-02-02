import 'package:flutter/material.dart';
import 'package:mindmate/screens/splash.dart';
import 'package:mindmate/screens/auth/login.dart';
import 'package:mindmate/screens/auth/signup.dart';
import 'package:mindmate/screens/home.dart';
import 'package:mindmate/screens/auth/forgot_password.dart';
import 'package:mindmate/screens/auth/verify_code.dart';
import 'package:mindmate/screens/auth/reset_password.dart';
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => Splash(),
        '/login': (context) => Login(),
        '/signup': (context) => Signup(),
        '/home': (context) => Home(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/verify-code') {
          final email = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => VerifyCodeScreen(email: email),
          );
        }
        if (settings.name == '/reset-password') {
          return MaterialPageRoute(builder: (context) => ResetPasswordScreen());
        }
        return null;
      },
    ),
  );
}
