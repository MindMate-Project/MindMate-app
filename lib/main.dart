import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:mindmate/core/navigation/app_navigation.dart';
import 'package:mindmate/core/navigation/app_router.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/core/network/patient_context_store.dart';
import 'package:mindmate/core/utils/responsive.dart';
import 'package:mindmate/features/auth/data/services/auth_service.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

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

  final patientContextStore = PatientContextStore();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(AuthService(), ProfileService()),
        ),

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
