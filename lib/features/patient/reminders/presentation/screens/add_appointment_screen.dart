import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';
import 'package:mindmate/core/widgets/date_picker_field.dart';
import 'package:mindmate/core/widgets/labeled_form_field.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/patient/reminders/data/mappers/reminder_api_mapper.dart';
import 'package:mindmate/features/patient/reminders/data/models/notify_before_options.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';
import 'package:mindmate/features/patient/reminders/presentation/widgets/notify_before_field.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key, this.initialReminder});

  /// When set, the screen edits this reminder (PUT) instead of creating (POST).
  final ReminderItem? initialReminder;

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = RemindersService();
  final _doctor = TextEditingController();
  final _specialty = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  String? _purpose;
  NotifyBeforeOptions _notifyBefore = const NotifyBeforeOptions();
  bool _submitting = false;

  static const _purposes = ['Consultation', 'Follow-Up', 'Lab', 'Scan'];

  bool get _isEdit => widget.initialReminder != null;

  DateTime get _datePickerFirstDate {
    if (!_isEdit) return DateTime.now();
    final r = widget.initialReminder!;
    final day =
        r.appointmentDate ?? ReminderApiMapper.dateOnly(r.scheduledTime);
    final today = ReminderApiMapper.dateOnly(DateTime.now());
    return day.isBefore(today) ? day : today;
  }

  @override
  void initState() {
    super.initState();
    final r = widget.initialReminder;
    if (r == null) return;
    _doctor.text = r.doctorName ?? '';
    _specialty.text = r.specialty ?? '';
    _location.text = r.location ?? '';
    _notes.text = r.notes ?? '';
    _purpose = ReminderApiMapper.appointmentTypeToUi(r.appointmentType);
    _date = r.appointmentDate ?? ReminderApiMapper.dateOnly(r.scheduledTime);
    _time = TimeOfDay.fromDateTime(r.scheduledTime);
  }

  @override
  void dispose() {
    _doctor.dispose();
    _specialty.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;

  String? _caregiverId() {
    final state = context.read<AuthCubit>().state;
    if (state is AuthSuccess && state.user.id != null) {
      return state.user.id;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_date == null || _time == null || _purpose == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete date, time, and purpose'),
        ),
      );
      return;
    }

    final caregiverId = _caregiverId();
    if (caregiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in as a caregiver')),
      );
      return;
    }

    final scheduled = ReminderApiMapper.mergeDateAndTime(_date!, _time!);
    if (!_isEdit && scheduled.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment time cannot be in the past')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final existing = widget.initialReminder;
      if (existing != null) {
        await _service.updateAppointment(
          id: existing.id,
          caregiverId: caregiverId,
          doctorName: _doctor.text,
          specialty: _specialty.text,
          location: _location.text,
          appointmentTypeUi: _purpose!,
          appointmentDate: _date!,
          appointmentTime: _time!,
          notes: _notes.text,
        );
      } else {
        await _service.createAppointment(
          caregiverId: caregiverId,
          doctorName: _doctor.text,
          specialty: _specialty.text,
          location: _location.text,
          appointmentTypeUi: _purpose!,
          appointmentDate: _date!,
          appointmentTime: _time!,
          notifyBefore: _notifyBefore,
          notes: _notes.text,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralWhite,
      appBar: ProfileAppBar(
        title: _isEdit ? 'Edit Appointment' : 'Add New Appointment',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            LabeledFormField(
              label: 'Doctor Name *',
              child: CustomTextFormField(
                controller: _doctor,
                hintText: 'Khaled ali',
                validator: _required,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            LabeledFormField(
              label: 'Specialty *',
              child: CustomTextFormField(
                controller: _specialty,
                hintText: 'Cardiology',
                validator: _required,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            LabeledFormField(
              label: 'Location *',
              child: CustomTextFormField(
                controller: _location,
                hintText: 'Qasr El Einy Hospital',
                validator: _required,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            LabeledFormField(
              label: 'Purpose *',
              child: RadioGroup<String>(
                groupValue: _purpose,
                onChanged: _submitting
                    ? (_) {}
                    : (v) => setState(() => _purpose = v),
                child: Column(
                  children: _purposes
                      .map(
                        (p) => RadioListTile<String>(
                          title: Text(p, style: AppTheme.label),
                          value: p,
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: LabeledFormField(
                    label: 'Date *',
                    child: DatePickerField(
                      selectedDate: _date,
                      onDateSelected: (d) => setState(() => _date = d),
                      hintText: 'Select date',
                      dateFormat: DateFormat('dd-MM-yyyy'),
                      firstDate: _datePickerFirstDate,
                      lastDate: DateTime(2100),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  flex: 2,
                  child: LabeledFormField(
                    label: 'Time *',
                    child: TimePickerField(
                      selectedTime: _time,
                      onTimeSelected: (t) => setState(() => _time = t),
                      hintText: '10:00 AM',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            if (!_isEdit)
              NotifyBeforeField(
                value: _notifyBefore,
                enabled: !_submitting,
                onChanged: (v) => setState(() => _notifyBefore = v),
              ),
            if (!_isEdit) const SizedBox(height: AppTheme.spacingL),
            const SizedBox(height: AppTheme.spacingL),
            LabeledFormField(
              label: 'Notes',
              child: CustomTextFormField(controller: _notes, hintText: ''),
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.neutralWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.neutralWhite,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
