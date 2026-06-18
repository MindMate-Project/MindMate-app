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
import 'package:mindmate/features/assignments/presentation/screens/assign_patient.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/caregiver/home/presentation/models/active_patient.dart';
import 'package:mindmate/features/caregiver/home/presentation/screens/caregiver_notifications_screen.dart';
import 'package:mindmate/features/caregiver/home/presentation/widgets/active_patient_sections.dart';
import 'package:mindmate/features/caregiver/home/presentation/widgets/patient_card.dart';
import 'package:mindmate/features/memory/data/services/memory_training_service.dart';

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
  List<AssignedPatientRow> _patients = const [];
  ActivePatient? _activePatient;

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

      if (patients.isEmpty) {
        await _patientContextStore.clearActivePatientId();
      } else {
        final match = _findPatient(storedId, patients);
        nextActive = ActivePatient.fromRow(match ?? patients.first);
        await _patientContextStore.setActivePatientId(nextActive.id);
      }

      if (!mounted) return;
      setState(() {
        _patients = patients;
        _activePatient = nextActive;
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

  Future<void> _selectPatient(AssignedPatientRow patient) async {
    await _patientContextStore.setActivePatientId(patient.patientId);
    if (!mounted) return;
    setState(() => _activePatient = ActivePatient.fromRow(patient));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patient selected for caregiver features')),
    );
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
                _PatientsSection(
                  loading: _loadingPatients,
                  error: _patientsError,
                  patients: _patients,
                  activePatientId: _activePatient?.id,
                  onRetry: _loadPatients,
                  onAddPatient: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const AddPatient(),
                      ),
                    );
                    await _loadPatients();
                  },
                  onSelectPatient: _selectPatient,
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

class _PatientsSection extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<AssignedPatientRow> patients;
  final String? activePatientId;
  final VoidCallback onRetry;
  final Future<void> Function() onAddPatient;
  final ValueChanged<AssignedPatientRow> onSelectPatient;

  const _PatientsSection({
    required this.loading,
    required this.error,
    required this.patients,
    required this.activePatientId,
    required this.onRetry,
    required this.onAddPatient,
    required this.onSelectPatient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Current Patients',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onAddPatient,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
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
        else if (patients.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 16),
            child: InfoMessageBox(
              message:
                  'No connected patient yet. Add a patient first. '
                  'Features that need a patient ID will stay unavailable.',
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return PatientCard(
                name: patient.name,
                relation: patient.relationship ?? '—',
                isSelected: activePatientId == patient.patientId,
                onTap: () => onSelectPatient(patient),
              );
            },
          ),
      ],
    );
  }
}
