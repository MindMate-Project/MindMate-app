import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mindmate/core/navigation/app_navigation.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/core/services/fcm_service.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/memory/data/services/memory_training_service.dart';

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

    context.go(route);

    // If a reminder alarm cold-launched the app, ring it now — but only on
    // the patient's device. Caregivers get tray push only, no full-screen alarm.
    final pendingAlarm = MemoryTrainingService.instance.pendingAlarmLaunch;
    if (pendingAlarm != null) {
      MemoryTrainingService.instance.pendingAlarmLaunch = null;
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user.isPatient) {
        Future.delayed(
          const Duration(milliseconds: 800),
          () => showReminderAlarm(pendingAlarm.$1, pendingAlarm.$2),
        );
      }
    }

    // Cold-start FCM tap: navigate once auth and the home route have settled.
    final pendingFcm = FcmService.instance.pendingOpenedMessage;
    if (pendingFcm != null) {
      FcmService.instance.pendingOpenedMessage = null;
      Future.delayed(
        const Duration(milliseconds: 800),
        () {
          if (!mounted) return;
          FcmService.instance.handleReminderMessageOpened(
            pendingFcm,
            context.read<AuthCubit>().state,
          );
        },
      );
    }
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
