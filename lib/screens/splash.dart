import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mindmate/themes/app_theme.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    startTimer();
    super.initState();
  }

  startTimer() {
    var duration = Duration(seconds: 10);
    return Timer(duration, route);
  }

  route() {
    Navigator.of(context).pushReplacementNamed('/roleSelection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/images/splash.png'),
            SizedBox(height: 21),
            Text(
              'MindMate',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: Color(0XFF14274E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
