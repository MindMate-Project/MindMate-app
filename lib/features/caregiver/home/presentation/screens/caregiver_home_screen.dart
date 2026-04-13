import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
// import 'package:mindmate/core/widgets/bottom_nav_bar_widget.dart';
import 'package:mindmate/core/widgets/caregiver_bottom_nav.dart';
import '../widgets/patient_card.dart';
import 'package:mindmate/core/widgets/appointment_card.dart';
import 'package:mindmate/core/widgets/medication_card.dart';
import 'package:mindmate/features/caregiver/home/presentation/screens/assign_patient.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({Key? key}) : super(key: key);

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  int _selectedIndex = 0;

  // Mock patient data
  final List<Map<String, dynamic>> patients = [
    {
      'id': '1',
      'name': 'Ahmed Mohamed',
      'relation': 'Father',
    },
  ];

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
        Expanded(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: const Icon(Icons.person),
          ),
        ),
        const SizedBox(width: 15),
        Column(
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
              onPressed: () {
                // Handle add patient
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddPatient()),
                );
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return PatientCard(
              name: patient['name'],
              relation: patient['relation'],
              // imageUrl: patient['imageUrl'],
              onTap: () {
                // Navigate to patient detail
              },
            );
          },
        ),
      ],
    );
  }
}
