import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/utils/responsive.dart';
import 'package:mindmate/core/widgets/appointment_card.dart';
import 'package:mindmate/core/widgets/medication_card.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_state.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/add_appointment_screen.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/add_medication_screen.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/reminder_detail_screen.dart';
import 'package:mindmate/features/patient/reminders/data/utils/reminder_filters.dart';
import 'package:mindmate/features/patient/reminders/presentation/utils/reminder_formatters.dart';
import 'package:mindmate/features/patient/reminders/presentation/widgets/week_calenddar.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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

  bool _isCaregiver(AuthState authState) => AppBottomNav.isCaregiver(authState);

  Future<void> _openDetail(String reminderId) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReminderDetailScreen(reminderId: reminderId),
      ),
    );
    if (deleted == true) {
      _remindersCubit.loadPatientReminders();
    }
  }

  Future<void> _onCaregiverAddPressed() async {
    final isAppointmentsTab = _tabController.index == 0;
    final page = isAppointmentsTab
        ? const AddAppointmentScreen()
        : const AddMedicationScreen();
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => page));
    if (created == true) {
      _remindersCubit.loadPatientReminders();
    }
  }

  void _onRemindersBackPressed(BuildContext context, bool isCaregiver) {
    Navigator.pushReplacementNamed(
      context,
      isCaregiver ? '/caregiver_home' : '/patient_home',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _remindersCubit,
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isCaregiver = _isCaregiver(authState);
          return Scaffold(
            backgroundColor: AppTheme.backgroundWhite,
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: 30,
                  color: AppTheme.neutralWhite,
                ),
                onPressed: () => _onRemindersBackPressed(context, isCaregiver),
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
                if (isCaregiver)
                  IconButton(
                    onPressed: _onCaregiverAddPressed,
                    icon: Icon(
                      Icons.add_rounded,
                      size: 28,
                      color: AppTheme.neutralWhite,
                    ),
                    tooltip: 'Add',
                  )
                else
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
            body: SafeArea(
              minimum: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  // Tabs
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.neutralLight,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(50),
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
                                      ReminderFilters.isAppointment(r) &&
                                      DateUtils.isSameDay(
                                        ReminderFilters.calendarDay(r),
                                        _selectedDate,
                                      ),
                                )
                                .toList()
                              ..sort(
                                (a, b) => ReminderFilters.displayDateTime(
                                  a,
                                ).compareTo(ReminderFilters.displayDateTime(b)),
                              );

                        final medications =
                            reminders
                                .where(
                                  (r) =>
                                      ReminderFilters.isMedication(r) &&
                                      DateUtils.isSameDay(
                                        ReminderFilters.calendarDay(r),
                                        _selectedDate,
                                      ),
                                )
                                .toList()
                              ..sort(
                                (a, b) => ReminderFilters.displayDateTime(
                                  a,
                                ).compareTo(ReminderFilters.displayDateTime(b)),
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
                                    final when =
                                        ReminderFilters.displayDateTime(ap);

                                    return AppointmentCard(
                                      doctorName:
                                          ap.doctorName ?? 'Unknown doctor',
                                      specialty:
                                          ap.specialty ?? 'Unknown specialty',
                                      location:
                                          ap.location ?? 'Unknown location',
                                      date: ReminderFormatters.listDate(when),
                                      time: ReminderFormatters.time12(when),
                                      type: ReminderFormatters.displayLabel(
                                        ap.appointmentType ?? 'appointment',
                                      ),
                                      onTap: () => _openDetail(ap.id),
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
                                    final when =
                                        ReminderFilters.displayDateTime(md);
                                    return MedicationCard(
                                      name:
                                          md.medicineName ?? 'Unknown medicine',
                                      dosage: md.dosage ?? '—',
                                      frequency:
                                          md.frequency?.isNotEmpty == true
                                          ? ReminderFormatters.displayLabel(
                                              md.frequency,
                                            )
                                          : 'Daily',
                                      startDate: md.startDate ?? when,
                                      endDate: md.endDate,
                                      time: ReminderFormatters.time12(when),
                                      onTap: () => _openDetail(md.id),
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
            ),
            bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
          );
        },
      ),
    );
  }
}
