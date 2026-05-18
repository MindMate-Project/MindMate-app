import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/detail_stat_tile.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminder_detail_cubit.dart';
import 'package:mindmate/features/patient/reminders/presentation/cubit/reminder_detail_state.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/add_appointment_screen.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/add_medication_screen.dart';
import 'package:mindmate/features/patient/reminders/data/utils/reminder_filters.dart';
import 'package:mindmate/features/patient/reminders/presentation/utils/reminder_formatters.dart';

class ReminderDetailScreen extends StatelessWidget {
  const ReminderDetailScreen({super.key, required this.reminderId});

  final String reminderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReminderDetailCubit(RemindersService())..load(reminderId),
      child: const _ReminderDetailView(),
    );
  }
}

class _ReminderDetailView extends StatelessWidget {
  const _ReminderDetailView();

  bool _isAppointment(ReminderItem item) =>
      item.type.toLowerCase() == 'appointment';

  Future<void> _confirmDelete(BuildContext context, ReminderItem item) async {
    final name = _isAppointment(item)
        ? ReminderFormatters.doctorName(item.doctorName)
        : (item.medicineName ?? 'this medicine');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $name?'),
        content: Text(
          _isAppointment(item)
              ? 'All data related to this appointment will be lost.'
              : 'All data related to this medication will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok = await context.read<ReminderDetailCubit>().delete(item.id);
    if (!context.mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete reminder')),
      );
    }
  }

  void _onEdit(BuildContext context, ReminderItem item) {
    final page = _isAppointment(item)
        ? const AddAppointmentScreen()
        : const AddMedicationScreen();
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderDetailCubit, ReminderDetailState>(
      builder: (context, state) {
        final isCaregiver = context.select(
          (AuthCubit c) => AppBottomNav.isCaregiver(c.state),
        );

        String title = 'Reminder';
        if (state is ReminderDetailLoaded) {
          title = _isAppointment(state.item)
              ? 'Appointment Information'
              : 'Medicine Information';
        } else if (state is ReminderDetailDeleting) {
          title = _isAppointment(state.item)
              ? 'Appointment Information'
              : 'Medicine Information';
        }

        return Scaffold(
          backgroundColor: AppTheme.neutralWhite,
          appBar: ProfileAppBar(title: title),
          bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
          body: switch (state) {
            ReminderDetailLoading() => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
            ReminderDetailError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Text(message, textAlign: TextAlign.center),
              ),
            ),
            ReminderDetailLoaded(:final item) ||
            ReminderDetailDeleting(:final item) => _DetailBody(
              item: item,
              isDeleting: state is ReminderDetailDeleting,
              isCaregiver: isCaregiver,
              onEdit: () => _onEdit(context, item),
              onDelete: () => _confirmDelete(context, item),
            ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.item,
    required this.isDeleting,
    required this.isCaregiver,
    required this.onEdit,
    required this.onDelete,
  });

  final ReminderItem item;
  final bool isDeleting;
  final bool isCaregiver;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  bool get _isAppointment => item.type.toLowerCase() == 'appointment';

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            if (_isAppointment)
              _AppointmentContent(item: item)
            else
              _MedicationContent(item: item),
            if (isCaregiver) ...[
              const SizedBox(height: AppTheme.spacingXXL),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isDeleting ? null : onEdit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.neutralWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isDeleting ? null : onDelete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: AppTheme.neutralWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        if (isDeleting)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.white.withValues(alpha: 0.6),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            ),
          ),
      ],
    );
  }
}

class _AppointmentContent extends StatelessWidget {
  const _AppointmentContent({required this.item});

  final ReminderItem item;

  @override
  Widget build(BuildContext context) {
    final when = ReminderFilters.displayDateTime(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.neutralLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ReminderFormatters.doctorName(item.doctorName),
                style: AppTheme.heading3.copyWith(
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ReminderFormatters.displayLabel(item.specialty),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Location',
          style: AppTheme.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacingS),
        _InfoRow(icon: Icons.location_on_outlined, text: item.location ?? '—'),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Schedule',
          style: AppTheme.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          children: [
            Expanded(
              child: DetailStatTile(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: ReminderFormatters.dayMonthYear(when),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: DetailStatTile(
                icon: Icons.schedule,
                label: 'Time',
                value: ReminderFormatters.time12(when),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Purpose Of Visit',
          style: AppTheme.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacingS),
        _InfoRow(text: ReminderFormatters.displayLabel(item.appointmentType)),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Notes',
          style: AppTheme.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacingS),
        _InfoRow(
          text: item.notes?.trim().isNotEmpty == true ? item.notes! : '—',
        ),
      ],
    );
  }
}

class _MedicationContent extends StatelessWidget {
  const _MedicationContent({required this.item});

  final ReminderItem item;

  @override
  Widget build(BuildContext context) {
    final when = ReminderFilters.displayDateTime(item);
    final start = item.startDate ?? when;
    final end = item.endDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.neutralLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFFFF1B8),
                child: Icon(
                  Icons.medication_outlined,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingL),
              Expanded(
                child: Text(
                  item.medicineName ?? 'Unknown medicine',
                  style: AppTheme.heading3.copyWith(
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Schedule',
          style: AppTheme.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          children: [
            Expanded(
              child: DetailStatTile(
                icon: Icons.calendar_today_outlined,
                label: 'Start Date',
                value: ReminderFormatters.dayMonth(start),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: DetailStatTile(
                icon: Icons.calendar_today_outlined,
                label: 'End Date',
                value: end != null ? ReminderFormatters.dayMonth(end) : '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: DetailStatTile(
                icon: Icons.schedule,
                label: 'Time',
                value: ReminderFormatters.time12(when),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: DetailStatTile(
                icon: Icons.alarm,
                label: 'Frequency',
                value: ReminderFormatters.displayLabel(item.frequency),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingL),
        Text(
          'Dose',
          style: AppTheme.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppTheme.spacingS),
        Row(
          children: [
            Expanded(
              child: DetailStatTile(
                icon: Icons.medication_liquid,
                label: 'Type',
                value: ReminderFormatters.displayLabel(item.form),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: DetailStatTile(
                icon: Icons.medication_outlined,
                label: 'Amount',
                value: item.dosage ?? '—',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.neutralLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: AppTheme.spacingS),
          ],
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
