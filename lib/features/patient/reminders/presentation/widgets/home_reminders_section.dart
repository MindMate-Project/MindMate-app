import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/appointment_card.dart';
import 'package:mindmate/core/widgets/error_retry_view.dart';
import 'package:mindmate/core/widgets/medication_card.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';
import 'package:mindmate/features/patient/reminders/data/utils/reminder_filters.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminders_state.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/reminder_detail_screen.dart';
import 'package:mindmate/features/patient/reminders/presentation/utils/reminder_formatters.dart';

/// Home-screen summary of the active patient's real reminders: the next
/// upcoming appointment and the medications due today. Shared by the patient
/// and caregiver home screens (both resolve the patient via PatientContextStore).
///
/// When used on the caregiver home, place inside [ActivePatientSections] so
/// switching patients resets the cubit created in [initState].
class HomeRemindersSection extends StatefulWidget {
  const HomeRemindersSection({super.key});

  @override
  State<HomeRemindersSection> createState() => _HomeRemindersSectionState();
}

class _HomeRemindersSectionState extends State<HomeRemindersSection> {
  late final RemindersCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = RemindersCubit(RemindersService());
    _cubit.loadPatientReminders();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openDetail(String reminderId) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReminderDetailScreen(reminderId: reminderId),
      ),
    );
    if (mounted) _cubit.loadPatientReminders();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<RemindersCubit, RemindersState>(
        builder: (context, state) {
          if (state is RemindersInitial || state is RemindersLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            );
          }

          if (state is RemindersError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Upcoming Appointment'),
                const SizedBox(height: 12),
                ErrorRetryView(
                  message: state.message,
                  onRetry: _cubit.loadPatientReminders,
                  expand: false,
                ),
              ],
            );
          }

          final reminders =
              state is RemindersLoaded ? state.reminders : <ReminderItem>[];
          final appointment = ReminderFilters.nextAppointment(reminders);
          final medications =
              ReminderFilters.medicationsForDay(reminders, DateTime.now());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Upcoming Appointment'),
              const SizedBox(height: 12),
              if (appointment != null)
                _appointmentCard(appointment)
              else
                _emptyText('No upcoming appointment'),
              const SizedBox(height: 30),
              _sectionTitle("Today's Medicine"),
              const SizedBox(height: 12),
              if (medications.isEmpty)
                _emptyText('No medication for today')
              else
                ...medications.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _medicationCard(m),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _appointmentCard(ReminderItem ap) {
    final when = ReminderFilters.displayDateTime(ap);
    return AppointmentCard(
      doctorName: ap.doctorName ?? 'Unknown doctor',
      specialty: ap.specialty ?? 'Unknown specialty',
      location: ap.location ?? 'Unknown location',
      date: ReminderFormatters.listDate(when),
      time: ReminderFormatters.time12(when),
      type: ReminderFormatters.displayLabel(ap.appointmentType ?? 'appointment'),
      onTap: () => _openDetail(ap.id),
    );
  }

  Widget _medicationCard(ReminderItem md) {
    final when = ReminderFilters.displayDateTime(md);
    return MedicationCard(
      name: md.medicineName ?? 'Unknown medicine',
      dosage: md.dosage ?? '—',
      frequency: md.frequency?.isNotEmpty == true
          ? ReminderFormatters.displayLabel(md.frequency)
          : 'Daily',
      startDate: md.startDate ?? when,
      endDate: md.endDate,
      time: ReminderFormatters.time12(when),
      onTap: () => _openDetail(md.id),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      );

  Widget _emptyText(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: AppTheme.neutralMedium),
        ),
      );
}
