import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/utils/responsive.dart';
import 'package:mindmate/core/widgets/appointment_card.dart';
import 'package:mindmate/core/widgets/medication_card.dart';
import 'package:mindmate/core/widgets/bottom_nav_bar_widget.dart';

class Appointment {
  final DateTime date;
  final String doctorName;
  final String specialty;
  final String time;
  final String appointmentDate;

  const Appointment({
    required this.date,
    required this.doctorName,
    required this.specialty,
    required this.time,
    required this.appointmentDate,
  });
}

class Medication {
  final DateTime date;
  final String time;
  final String name;
  final String count;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;

  const Medication({
    required this.date,
    required this.time,
    required this.name,
    required this.count,
    this.frequency = 'Daily',
    required this.startDate,
    this.endDate,
  });
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedDayIndex;
  late DateTime _selectedDate;

  // test appointments and medication
  late final List<Appointment> _appointments;
  late final List<Medication> _medications;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final weekDays = _weekDays();
    final now = DateTime.now();

    // Find today's index in the week, default to Tuesday (index 1) if not found
    _selectedDayIndex = weekDays.indexWhere(
      (d) => d.year == now.year && d.month == now.month && d.day == now.day,
    );
    if (_selectedDayIndex == -1) {
      _selectedDayIndex = 1;
    }

    _selectedDate = weekDays[_selectedDayIndex];

    // test data
    _appointments = [
      // Monday (index 0)
      Appointment(
        date: weekDays[0],
        doctorName: 'Dr. Sarah Ahmed',
        specialty: 'Neurologist',
        time: '10:00 AM',
        appointmentDate: _formatAppointmentDate(weekDays[0]),
      ),
      // Tuesday (index 1)
      Appointment(
        date: weekDays[1],
        doctorName: 'Dr. Khaled Ali',
        specialty: 'Cardiologist',
        time: '09:00 AM',
        appointmentDate: _formatAppointmentDate(weekDays[1]),
      ),
      Appointment(
        date: weekDays[1],
        doctorName: 'Dr. Khaled Ali',
        specialty: 'Cardiologist',
        time: '02:00 PM',
        appointmentDate: _formatAppointmentDate(weekDays[1]),
      ),
      // Wednesday (index 2)
      Appointment(
        date: weekDays[2],
        doctorName: 'Dr. Mohamed Hassan',
        specialty: 'Dermatologist',
        time: '11:00 AM',
        appointmentDate: _formatAppointmentDate(weekDays[2]),
      ),
    ];

    _medications = [
      // Tuesday (index 1)
      Medication(
        date: weekDays[1],
        time: '8:00 am',
        name: 'Amlodipine',
        count: '1 tablet',
        startDate: DateTime(now.year, 7, 25),
        endDate: DateTime(now.year, 3, 25),
      ),
      Medication(
        date: weekDays[1],
        time: '2:00 pm',
        name: 'Aspirin',
        count: '1 tablet',
        startDate: DateTime(now.year, 7, 25),
        endDate: DateTime(now.year, 3, 25),
      ),
      Medication(
        date: weekDays[1],
        time: '6:30 pm',
        name: 'Memantine',
        count: '1 tablet',
        startDate: DateTime(now.year, 7, 25),
        endDate: DateTime(now.year, 3, 25),
      ),
      Medication(
        date: weekDays[1],
        time: '10:00 pm',
        name: 'Donepezil',
        count: '1 tablet',
        startDate: DateTime(now.year, 7, 25),
        endDate: DateTime(now.year, 3, 25),
      ),
      // Friday (index 4)
      Medication(
        date: weekDays[4],
        time: '7:00 am',
        name: 'Donepezil',
        count: '1 tablet',
        startDate: DateTime(now.year, 7, 25),
        endDate: DateTime(now.year, 3, 25),
      ),
      Medication(
        date: weekDays[4],
        time: '3:00 pm',
        name: 'Memantine',
        count: '1 tablet',
        startDate: DateTime(now.year, 7, 25),
        endDate: DateTime(now.year, 3, 25),
      ),
      Medication(
        date: weekDays[4],
        time: '9:00 pm',
        name: 'Amlodipine',
        count: '1 tablet',
        startDate: DateTime(now.year, 7, 25),
        endDate: DateTime(now.year, 3, 25),
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime> _weekDays() {
    final now = DateTime.now();
    // Start from Monday
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(
      7,
      (i) => DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i),
    );
  }

  Widget _buildWeekCalendar() {
    final days = _weekDays();
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        children: [
          // Day names row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayNames
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.neutralDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          SizedBox(height: 8.h),
          // Dates row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final d = days[index];
              final isSelected = index == _selectedDayIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDayIndex = index;
                      _selectedDate = d;
                    });
                  },
                  child: Container(
                    height: 44.w,
                    alignment: Alignment.center,
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.neutralSkyBlue
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isSelected
                              ? AppTheme.neutralWhite
                              : AppTheme.neutralDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return MedicationCard(
      name: medication.name,
      dosage: medication.count,
      frequency: medication.frequency,
      startDate: medication.startDate,
      endDate: medication.endDate,
      time: medication.time,
    );
  }

  String _formatDateHeader(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final now = DateTime.now();
    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;

    final dayName = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;

    return isToday
        ? 'Today $dayName, $day $month $year'
        : '$dayName, $day $month $year';
  }

  String _formatAppointmentDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd-$mm-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 30,
            color: AppTheme.neutralWhite,
          ),
          onPressed: () => Navigator.pushNamed(context, '/patient_home'),
        ),
        title: Text(
          "Reminders",
          style: TextStyle(
            fontSize: 20,
            color: AppTheme.neutralWhite,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications,
              size: 24,
              color: AppTheme.neutralWhite,
            ),
          ),
        ],
        backgroundColor: AppTheme.neutralSkyBlue,
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
            decoration: BoxDecoration(
              color: AppTheme.neutralLight,
              borderRadius: BorderRadius.circular(40.w),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(40.w),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppTheme.neutralWhite,
              unselectedLabelColor: AppTheme.neutralBlack,
              labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              unselectedLabelStyle: TextStyle(fontSize: 16),
              tabs: [
                Tab(text: 'Appointments'),
                Tab(text: 'Medication'),
              ],
            ),
          ),

          // Week calendar
          _buildWeekCalendar(),

          // Date header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _formatDateHeader(_selectedDate),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutralDark,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Appointments tab
                Builder(
                  builder: (context) {
                    final appointments = _appointments
                        .where((a) => _isSameDay(a.date, _selectedDate))
                        .toList();

                    if (appointments.isEmpty) {
                      return Center(
                        child: Text(
                          'No appointments for this day',
                          style: TextStyle(
                            color: AppTheme.neutralMedium,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      // padding: EdgeInsets.only(bottom: 16.h),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        final ap = appointments[index];
                        return AppointmentCard(
                          doctorName: ap.doctorName,
                          specialty: ap.specialty,
                          location: 'Qasr El Einy Hospital',
                          date: ap.appointmentDate,
                          time: ap.time,
                          type: 'follow-up',
                        );
                      },
                    );
                  },
                ),

                // Medication tab
                Builder(
                  builder: (context) {
                    final medications = _medications
                        .where((m) => _isSameDay(m.date, _selectedDate))
                        .toList();

                    if (medications.isEmpty) {
                      return Center(
                        child: Text(
                          'No medications for this day',
                          style: TextStyle(
                            color: AppTheme.neutralMedium,
                            fontSize: 14.sp,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      // padding: EdgeInsets.all(16),
                      itemCount: medications.length,
                      itemBuilder: (context, index) {
                        final md = medications[index];
                        return MedicationCard(
                          name: md.name,
                          dosage: md.count,
                          frequency: md.frequency,
                          startDate: md.startDate,
                          time: md.time,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/patient_home');
              break;
            case 1:
              Navigator.pushNamed(context, '/memory');
              break;
            case 4:
              Navigator.pushNamed(context, '/profile');
              break;
            default:
              break;
          }
        },
      ),
    );
  }
}
