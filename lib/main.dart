import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:mindmate/core/navigation/app_navigation.dart';
import 'package:mindmate/core/navigation/app_router.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/core/network/patient_context_store.dart';
import 'package:mindmate/core/services/caregiver_notification_preferences.dart';
import 'package:mindmate/core/services/fcm_service.dart';
import 'package:mindmate/core/utils/responsive.dart';
import 'package:mindmate/features/alerts/presentation/cubit/alert_cubit.dart';
import 'package:mindmate/features/auth/data/services/auth_service.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/location/data/services/geofence_alert_service.dart';
import 'package:mindmate/features/location/data/services/location_service.dart';
import 'package:mindmate/features/location/presentation/cubit/location_cubit.dart';
import 'package:mindmate/features/memory/data/services/memory_service.dart';
import 'package:mindmate/features/memory/data/services/memory_training_service.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_cubit.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:mindmate/features/profile/data/services/profile_service.dart';
import 'package:mindmate/features/profile/presentation/cubit/profile_cubit.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('[FCM] Background message received: ${message.messageId}');

  // Notification payloads are shown by the OS tray. Data-only payloads need a
  // local notification because Flutter is not running in the foreground.
  if (message.notification == null && message.data.isNotEmpty) {
    final plugin =
        await FcmService.instance.createBackgroundNotificationsPlugin();
    await FcmService.instance.showRemoteMessage(message, plugin);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  tz.initializeTimeZones();

  await CaregiverNotificationPreferences.instance.load();

  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  await MemoryTrainingService.instance.init(
    onTap: (memoryId) {
      AppRouter.router.push(
        AppRoutes.memoryDrill,
        extra: memoryId == null ? null : {'memoryId': memoryId},
      );
    },

    onReminderTap: (reminderId) {
      AppRouter.router.push(AppRoutes.reminderDetail(reminderId));
    },
    onReminderAlarm: showReminderAlarm,
    notificationsPlugin: notificationsPlugin,
  );

  await FcmService.instance.ensureAndroidChannel(notificationsPlugin);
  await FcmService.instance.ensureNotificationPermissions(notificationsPlugin);

  final authCubit = AuthCubit(AuthService(), ProfileService());
  final alertCubit = AlertCubit();
  final patientContextStore = PatientContextStore();

  // Handle FCM messages when the app is open (foreground).
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final authState = authCubit.state;
    final reminderId = message.data['reminderId']?.toString();
    if (authState is AuthSuccess &&
        authState.user.isPatient &&
        reminderId != null &&
        reminderId.isNotEmpty) {
      showReminderAlarm(message.hashCode, reminderId);
    } else {
      unawaited(
        FcmService.instance.showRemoteMessage(message, notificationsPlugin),
      );
    }

    if (authState is AuthSuccess && authState.user.isCaregiver) {
      unawaited(alertCubit.loadAlerts());
    }
  });

  // Handle notification tap when app is in background (but not terminated).
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint(
      '[FCM] App opened from background notification: ${message.data}',
    );
    FcmService.instance.handleReminderMessageOpened(message, authCubit.state);
  });

  // Handle notification tap when app was fully terminated.
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint(
      '[FCM] App launched from terminated notification: ${initialMessage.data}',
    );
    FcmService.instance.pendingOpenedMessage = initialMessage;
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),

        BlocProvider.value(value: alertCubit),

        BlocProvider(create: (context) => MemoryCubit(MemoryService())),

        BlocProvider(create: (context) => ProfileCubit(ProfileService())),

        BlocProvider(
          create: (context) => RemindersCubit(
            RemindersService(patientContextStore: patientContextStore),
          ),
        ),

        BlocProvider(
          create: (context) => LocationCubit(
            LocationService(),
            geofenceAlertService: GeofenceAlertService(
              notifications: notificationsPlugin,
            ),
          ),
        ),
      ],
      child: const MindMateApp(),
    ),
  );
}

class MindMateApp extends StatelessWidget {
  const MindMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final baseTheme = ThemeData.light();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      routerConfig: AppRouter.router,

      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.cairoTextTheme(baseTheme.textTheme),
        primaryTextTheme: GoogleFonts.cairoTextTheme(
          baseTheme.primaryTextTheme,
        ),
      ),
    );
  }
}
