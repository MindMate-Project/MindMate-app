import 'package:flutter/material.dart';
import 'package:mindmate/core/network/patient_context_store.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/error_retry_view.dart';
import 'package:mindmate/core/widgets/info_message_box.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/assignments/data/models/assigned_patient_row.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/assignments/presentation/screens/assign_patient.dart';
import 'package:mindmate/features/caregiver/home/presentation/widgets/patient_card.dart';
import 'package:mindmate/features/caregiver/patients/presentation/screens/patient_detail_screen.dart';

/// Lists all patients assigned to the caregiver. Accessible from profile.
class CaregiverPatientsScreen extends StatefulWidget {
  const CaregiverPatientsScreen({super.key});

  @override
  State<CaregiverPatientsScreen> createState() =>
      _CaregiverPatientsScreenState();
}

class _CaregiverPatientsScreenState extends State<CaregiverPatientsScreen> {
  final AssignmentService _assignmentService = AssignmentService();
  final PatientContextStore _patientContextStore = PatientContextStore();

  bool _loading = true;
  String? _error;
  List<AssignedPatientRow> _patients = const [];
  String? _activePatientId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patients = await _assignmentService.fetchCaregiverPatients();
      final activeId = await _patientContextStore.getActivePatientId();
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _activePatientId = activeId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _selectPatient(AssignedPatientRow patient) async {
    await _patientContextStore.setActivePatientId(patient.patientId);
    if (!mounted) return;
    setState(() => _activePatientId = patient.patientId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patient selected for caregiver features')),
    );
  }

  Future<void> _openDetails(String patientId) async {
    final removed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PatientDetailScreen(patientId: patientId),
      ),
    );
    if (removed == true) {
      await _patientContextStore.clearActivePatientId();
      await _load();
    }
  }

  Future<void> _addPatient() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const AddPatient()),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ProfileAppBar(title: 'Patients'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Connected Patients',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addPatient,
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
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      )
                    else if (_error != null)
                      ErrorRetryView(
                        message: _error!,
                        onRetry: _load,
                        expand: false,
                      )
                    else if (_patients.isEmpty)
                      const InfoMessageBox(
                        message:
                            'No connected patient yet. Add a patient to get started.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _patients.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 0),
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return PatientCard(
                            name: patient.name,
                            relation: patient.relationship ?? '—',
                            isSelected: _activePatientId == patient.patientId,
                            onTap: () => _selectPatient(patient),
                            onDetailsTap: () => _openDetails(patient.patientId),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
    );
  }
}
