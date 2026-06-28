import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/core/widgets/user_avatar.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/memory/data/models/memory_item.dart';
import 'package:mindmate/features/memory/data/services/memory_training_service.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_cubit.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_state.dart';
import 'package:mindmate/features/patient/face_recognition/face_recognition.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminder_notification_service.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_state.dart';
import 'package:mindmate/features/patient/home/presentation/widgets/patient_sos_button.dart';
import 'package:mindmate/features/patient/reminders/presentation/widgets/home_reminders_section.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({super.key});

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyTrainingSchedule();
      // Patient device only: schedule local notifications for the patient's
      // reminders (delivery used to rely on a push path that never fired).
      unawaited(ReminderNotificationService.instance.syncFromServer());
      final cubit = context.read<RemindersCubit>();
      if (cubit.state is! RemindersLoading) {
        cubit.loadPatientReminders();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<RemindersCubit>().loadPatientReminders();
      unawaited(ReminderNotificationService.instance.syncFromServer());
    }
  }

  Future<void> _applyTrainingSchedule() async {
    if (!mounted) return;
    final cubit = context.read<MemoryCubit>();
    if (cubit.state is! MemoryLoaded) {
      await cubit.loadMemories();
    }
    final state = cubit.state;
    final memories = state is MemoryLoaded
        ? <MemoryItem>[...state.photos, ...state.videos, ...state.texts]
        : const <MemoryItem>[];
    await MemoryTrainingService.instance.applyForPatient(memories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top greeting section
                _buildGreetingSection(),
                const SizedBox(height: 24),

                const PatientSosButton(),
                const SizedBox(height: 30),

                // upcoming appointment + today's medicine, from the patient's
                // real reminders
                const HomeRemindersSection(),
                const SizedBox(height: 30),

                // quick Actions section
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
    );
  }

  Widget _buildGreetingSection() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthSuccess ? state.user : null;
        final fullName = user?.name.trim() ?? '';
        final firstName = fullName.isEmpty
            ? 'there'
            : fullName.split(RegExp(r'\s+')).first;
        final today = DateFormat('EEEE, d MMM').format(DateTime.now());

        return Row(
          children: [
            // Profile picture: photo when available, else initial/icon.
            UserAvatar(photoUrl: user?.photoUrl, name: fullName, radius: 30),
            const SizedBox(width: 15),
            // Greeting text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $firstName',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    today,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          children: [
            _buildActionCard(
              icon: Icons.camera_alt,
              label: 'Face recognition',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FaceScanStartPage(),
                  ),
                );
              },
            ),
            _buildActionCard(
              icon: Icons.psychology,
              label: 'Memory Bank',
              onTap: () {
                context.push(AppRoutes.memory);
              },
            ),
            _buildActionCard(
              icon: Icons.access_time,
              label: 'Reminder',
              onTap: () {
                context.push(AppRoutes.patientReminders);
              },
            ),
            _buildActionCard(
              icon: Icons.medication,
              label: 'Medication',
              onTap: () {
                context.push(AppRoutes.patientMedication);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 15),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
