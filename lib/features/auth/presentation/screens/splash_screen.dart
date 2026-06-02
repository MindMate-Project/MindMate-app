import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    // Wake the free-tier backend during the splash delay so the first real
    // request after login doesn't hit a cold-start timeout.
    unawaited(ApiHttpClient.warmUp());
    _navigateWhenReady();
  }

  Future<void> _navigateWhenReady() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final route = await context.read<AuthCubit>().resolveStartRoute();
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(route);
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
            const SizedBox(height: 21),
            const Text(
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
