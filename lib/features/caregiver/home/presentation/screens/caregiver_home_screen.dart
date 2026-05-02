import 'package:flutter/material.dart';
import 'package:mindmate/core/network/patient_context_store.dart';
import 'package:mindmate/core/themes/app_theme.dart';
// import 'package:mindmate/core/widgets/bottom_nav_bar_widget.dart';
import 'package:mindmate/core/widgets/caregiver_bottom_nav.dart';
import 'package:mindmate/features/assignments/data/models/assigned_patient_row.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import '../widgets/patient_card.dart';
import 'package:mindmate/core/widgets/appointment_card.dart';
import 'package:mindmate/core/widgets/medication_card.dart';
import 'package:mindmate/features/assignments/presentation/screens/assign_patient.dart';
import 'package:mindmate/features/caregiver/home/presentation/screens/caregiver_notifications_screen.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({Key? key}) : super(key: key);

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  final AssignmentService _assignmentService = AssignmentService();
  final PatientContextStore _patientContextStore = PatientContextStore();

  bool _loadingPatients = true;
  String? _patientsError;
  List<AssignedPatientRow> _patients = const [];
  String? _activePatientId;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loadingPatients = true;
      _patientsError = null;
    });

    try {
      final patients = await _assignmentService.fetchCaregiverPatients();
      final stored = await _patientContextStore.getActivePatientId();
      String? nextActiveId;

      if (patients.isEmpty) {
        await _patientContextStore.clearActivePatientId();
      } else {
        final stillValid = stored != null &&
            patients.any((p) => p.patientId == stored);
        nextActiveId = stillValid ? stored : patients.first.patientId;
        await _patientContextStore.setActivePatientId(nextActiveId);
      }

      if (!mounted) return;
      setState(() {
        _patients = patients;
        _activePatientId = nextActiveId;
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

  Future<void> _selectPatient(String patientId) async {
    await _patientContextStore.setActivePatientId(patientId);
    if (!mounted) return;
    setState(() => _activePatientId = patientId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patient selected for caregiver features')),
    );
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
                _buildGreetingSection(),
                const SizedBox(height: 30),
                _buildPatientsSection(),
                AppointmentCard(
                  doctorName: 'Doctor Name',
                  specialty: 'Specialty',
                  type: 'Type',
                  date: '2024-06-01',
                  time: '10:00 AM',
                  location: 'Location',
                ),
                MedicationCard(
                  name: 'Medication Name',
                  dosage: '10mg',
                  frequency: 'Daily',
                  startDate: DateTime.now(),
                  time: 'Morning',
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CaregiverBottomNav(),
    );
  }

  Widget _buildGreetingSection() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
          ),
          child: const Icon(Icons.person),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hello, Caregiver',
                style: TextStyle(
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const CaregiverNotificationsScreen()),
            );
          },
          icon: const Icon(Icons.notifications_outlined),
          color: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildPatientsSection() {
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
              onPressed: () async {
                // Handle add patient
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (context) => const AddPatient()),
                );
                _loadPatients();
              },
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
        if (_loadingPatients)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          )
        else if (_patientsError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              _patientsError!,
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          )
        else if (_patients.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.neutralLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No connected patient yet. Add a patient first. '
              'Features that need a patient ID will stay unavailable.',
              style: TextStyle(color: AppTheme.neutralDark),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _patients.length,
            itemBuilder: (context, index) {
              final patient = _patients[index];
              return PatientCard(
                name: patient.name,
                relation: patient.relationship ?? '—',
                isSelected: _activePatientId == patient.patientId,
                onTap: () => _selectPatient(patient.patientId),
              );
            },
          ),
      ],
    );
  }
}
