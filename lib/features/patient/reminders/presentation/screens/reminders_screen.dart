import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/utils/responsive.dart';
import 'package:mindmate/core/widgets/appointment_card.dart';
import 'package:mindmate/core/widgets/medication_card.dart';
import 'package:mindmate/core/widgets/bottom_nav_bar_widget.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_state.dart';
import 'package:mindmate/features/patient/reminders/presentation/widgets/week_calenddar.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // late int _selectedDayIndex;
  DateTime _selectedDate = DateTime.now();
  late final RemindersCubit _remindersCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _remindersCubit = RemindersCubit(RemindersService());
    _remindersCubit.loadPatientReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _remindersCubit.close();
    super.dispose();
  }

  bool _isAppointment(ReminderItem reminder) {
    return reminder.type.toLowerCase() == 'appointment';
  }

  bool _isMedication(ReminderItem reminder) {
    return reminder.type.toLowerCase() == 'medication';
  }

  DateTime _reminderDate(ReminderItem reminder) {
    if (_isAppointment(reminder)) {
      // Appointments use `appointmentDate` when available.
      return reminder.appointmentDate ?? reminder.scheduledTime;
    }

    // Medication reminders are grouped by the reminder `scheduledTime` date.
    return reminder.scheduledTime;
  }

  String _formatTime12h(DateTime time) {
    return DateFormat('hh:mm a').format(time); // Outputs: 09:30 AM
  }

  String _formatAppointmentDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd-$mm-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _remindersCubit,
      child: Scaffold(
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
                labelStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(fontSize: 16),
                tabs: const [
                  Tab(text: 'Appointments'),
                  Tab(text: 'Medication'),
                ],
              ),
            ),

            // Week calendar
            WeeklyCalendarWidget(
              selectedDate: _selectedDate,
              onDateSelected: (newDate) {
                setState(() {
                  _selectedDate = newDate;
                });
              },
            ),

            // Content
            Expanded(
              child: BlocBuilder<RemindersCubit, RemindersState>(
                builder: (context, state) {
                  if (state is RemindersLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  if (state is RemindersError) {
                    return Center(
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.neutralMedium,
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  final reminders = state is RemindersLoaded
                      ? state.reminders
                      : <ReminderItem>[];

                  final appointments =
                      reminders
                          .where(
                            (r) =>
                                _isAppointment(r) &&
                                DateUtils.isSameDay(
                                  _reminderDate(r),
                                  _selectedDate,
                                ),
                          )
                          .toList()
                        ..sort(
                          (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
                        );

                  final medications =
                      reminders
                          .where(
                            (r) =>
                                _isMedication(r) &&
                                DateUtils.isSameDay(
                                  _reminderDate(r),
                                  _selectedDate,
                                ),
                          )
                          .toList()
                        ..sort(
                          (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
                        );

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Appointments tab
                      Builder(
                        builder: (context) {
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
                            itemCount: appointments.length,
                            itemBuilder: (context, index) {
                              final ap = appointments[index];
                              final date =
                                  ap.appointmentDate ?? ap.scheduledTime;

                              return AppointmentCard(
                                doctorName: ap.doctorName ?? 'Unknown doctor',
                                specialty: ap.specialty ?? 'Unknown specialty',
                                location: ap.location ?? 'Unknown location',
                                date: _formatAppointmentDate(date),
                                time: _formatTime12h(ap.scheduledTime),
                                type: ap.appointmentType ?? 'appointment',
                              );
                            },
                          );
                        },
                      ),

                      // Medication tab
                      Builder(
                        builder: (context) {
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
                            itemCount: medications.length,
                            itemBuilder: (context, index) {
                              final md = medications[index];
                              return MedicationCard(
                                name: md.medicineName ?? 'Unknown medicine',
                                dosage: md.dosage ?? '—',
                                frequency: md.frequency?.isNotEmpty == true
                                    ? md.frequency!
                                    : 'Daily',
                                startDate: md.startDate ?? md.scheduledTime,
                                endDate: md.endDate,
                                time: _formatTime12h(md.scheduledTime),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
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
      ),
    );
  }
}
