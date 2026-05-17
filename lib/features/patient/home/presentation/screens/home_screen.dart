import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/core/widgets/appointment_card.dart';
import 'package:mindmate/core/widgets/medicine_card.dart';
import 'package:mindmate/features/patient/face_recognition/face_recognition.dart';

class PatientHomePage extends StatefulWidget {
  const PatientHomePage({Key? key}) : super(key: key);

  @override
  State<PatientHomePage> createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {


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
                const SizedBox(height: 30),

                // upcoming Appointment section
                _buildUpcomingAppointment(),
                const SizedBox(height: 30),

                // today's Medicine section
                _buildTodaysMedicine(),
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
    return Row(
      children: [
        // Profile picture
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[300],
            image: const DecorationImage(
              image: NetworkImage('https://i.pravatar.cc/150?img=12'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 15),
        // Greeting text
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hello,',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateTime.now().toString(),
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Appointment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        AppointmentCard(
          doctorName: 'Dr. Khaled Ali',
          specialty: 'Cardiologist',
          location: 'Qasr El Einy Hospital',
          date: '07-02-2026',
          type: 'follow-up',
          time: '09:00 AM',
        ),
      ],
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
                Navigator.pushNamed(context, '/memory');
              },
            ),
            _buildActionCard(
              icon: Icons.access_time,
              label: 'Reminder',
              onTap: () {
                Navigator.pushNamed(context, '/patient_reminders');
              },
            ),
            _buildActionCard(
              icon: Icons.medication,
              label: 'Medication',
              onTap: () {},
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

  Widget _buildTodaysMedicine() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Medicine",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const MedicineCard(
          name: 'Metformin',
          dosage: '2 Capsules',
          frequency: 'Daily',
          time: '12:00 PM',
          startDate: '25 July',
          endDate: '25 March',
        ),
      ],
    );
  }
}
