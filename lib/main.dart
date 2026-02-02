import 'package:flutter/material.dart';
import 'package:mindmate/screens/splash.dart';
import 'package:mindmate/screens/auth/login.dart';
import 'package:mindmate/screens/auth/signup.dart';
import 'package:mindmate/screens/home.dart';

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
      },
    ),
  );
}
