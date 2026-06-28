import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/network/patient_context_store.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/utils/name_utils.dart';
import 'package:mindmate/core/widgets/error_retry_view.dart';
import 'package:mindmate/core/widgets/info_message_box.dart';
import 'package:mindmate/core/widgets/user_avatar.dart';
import 'package:mindmate/features/assignments/data/models/assigned_patient_row.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/caregiver/home/presentation/models/active_patient.dart';
import 'package:mindmate/features/caregiver/profile/presentation/screens/caregiver_notifications_screen.dart';
import 'package:mindmate/features/caregiver/home/presentation/widgets/active_patient_sections.dart';
import 'package:mindmate/features/caregiver/home/presentation/widgets/patient_card.dart';
import 'package:mindmate/features/caregiver/patients/presentation/screens/patient_detail_screen.dart';
import 'package:mindmate/features/memory/data/services/memory_training_service.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_cubit.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({super.key});

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  final AssignmentService _assignmentService = AssignmentService();
  final PatientContextStore _patientContextStore = PatientContextStore();

  bool _loadingPatients = true;
  String? _patientsError;
  ActivePatient? _activePatient;
  String? _activeRelation;

  @override
  void initState() {
    super.initState();
    MemoryTrainingService.instance.cancelForCaregiver();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loadingPatients = true;
      _patientsError = null;
    });

    try {
      final patients = await _assignmentService.fetchCaregiverPatients();
      final storedId = await _patientContextStore.getActivePatientId();
      ActivePatient? nextActive;
      String? relation;

      if (patients.isEmpty) {
        await _patientContextStore.clearActivePatientId();
      } else {
        final match = _findPatient(storedId, patients);
        final row = match ?? patients.first;
        nextActive = ActivePatient.fromRow(row);
        relation = row.relationship;
        await _patientContextStore.setActivePatientId(nextActive.id);
        if (mounted) context.read<RemindersCubit>().loadPatientReminders();
      }

      if (!mounted) return;
      setState(() {
        _activePatient = nextActive;
        _activeRelation = relation;
        _loadingPatients = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _patientsError = e.toString().replaceFirst('Exception: ', '');
        _loadingPatients = false;
      });
    }
  }

  Future<void> _openPatientDetails() async {
    final patient = _activePatient;
    if (patient == null) return;

    final removed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PatientDetailScreen(patientId: patient.id),
      ),
    );
    if (removed == true) {
      await _patientContextStore.clearActivePatientId();
      await _loadPatients();
    }
  }

  AssignedPatientRow? _findPatient(
    String? patientId,
    List<AssignedPatientRow> patients,
  ) {
    if (patientId == null) return null;
    for (final patient in patients) {
      if (patient.patientId == patientId) return patient;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GreetingSection(
                  onNotificationsTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const CaregiverNotificationsScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _ActivePatientSection(
                  loading: _loadingPatients,
                  error: _patientsError,
                  patient: _activePatient,
                  relation: _activeRelation,
                  onRetry: _loadPatients,
                  onTap: _openPatientDetails,
                ),
                if (_activePatient case final patient?) ...[
                  const SizedBox(height: 30),
                  ActivePatientSections(
                    key: ValueKey(patient.id),
                    patient: patient,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  final VoidCallback onNotificationsTap;

  const _GreetingSection({required this.onNotificationsTap});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthSuccess ? state.user : null;
        final name = firstNameOf(user?.name) ?? 'Caregiver';

        return Row(
          children: [
            UserAvatar(photoUrl: user?.photoUrl, name: user?.name, radius: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $name',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to take care of your patients today?',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: onNotificationsTap,
              icon: const Icon(Icons.notifications_outlined),
              color: AppTheme.primaryColor,
            ),
          ],
        );
      },
    );
  }
}

class _ActivePatientSection extends StatelessWidget {
  final bool loading;
  final String? error;
  final ActivePatient? patient;
  final String? relation;
  final VoidCallback onRetry;
  final VoidCallback onTap;

  const _ActivePatientSection({
    required this.loading,
    required this.error,
    required this.patient,
    required this.relation,
    required this.onRetry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Patient',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 15),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          )
        else if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ErrorRetryView(
              message: error!,
              onRetry: onRetry,
              expand: false,
            ),
          )
        else if (patient == null)
          const InfoMessageBox(
            message:
                'No connected patient yet. Add a patient from Profile → Patients.',
          )
        else
          PatientCard(
            name: patient!.name,
            relation: relation ?? '—',
            isSelected: true,
            onTap: onTap,
          ),
      ],
    );
  }
}
