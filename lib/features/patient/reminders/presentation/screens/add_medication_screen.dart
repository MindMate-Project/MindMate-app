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

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key, this.initialReminder});

  /// When set, the screen edits this reminder (PUT) instead of creating (POST).
  final ReminderItem? initialReminder;

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = RemindersService();
  final _drugName = TextEditingController();
  final _dosage = TextEditingController();
  final _timePerDay = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  TimeOfDay? _time;
  String? _type;
  String? _frequency;
  NotifyBeforeOptions _notifyBefore = const NotifyBeforeOptions();
  bool _submitting = false;

  static const _types = ['Tablet', 'Capsule', 'Syrup', 'Injection'];
  static const _frequencies = ['Once', 'Daily', 'Weekly'];

  bool get _isEdit => widget.initialReminder != null;

  DateTime get _fromDateFirstSelectable {
    if (!_isEdit) return DateTime.now();
    final r = widget.initialReminder!;
    final start =
        r.startDate ?? ReminderApiMapper.dateOnly(r.scheduledTime);
    final today = ReminderApiMapper.dateOnly(DateTime.now());
    return start.isBefore(today) ? start : today;
  }

  @override
  void initState() {
    super.initState();
    final r = widget.initialReminder;
    if (r == null) return;
    _drugName.text = r.medicineName ?? '';
    _dosage.text = r.dosage ?? '';
    if (r.timesPerDay != null) {
      _timePerDay.text = r.timesPerDay.toString();
    }
    final start = r.startDate ?? ReminderApiMapper.dateOnly(r.scheduledTime);
    _fromDate = start;
    _toDate = r.endDate ?? start;
    _time = TimeOfDay.fromDateTime(r.scheduledTime);
    _type = ReminderApiMapper.medicationFormToUi(r.form);
    _frequency = ReminderApiMapper.frequencyToUi(r.frequency);
  }

  @override
  void dispose() {
    _drugName.dispose();
    _dosage.dispose();
    _timePerDay.dispose();
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
    if (_type == null || _frequency == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete type, frequency, and time')),
      );
      return;
    }
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose from and to dates')),
      );
      return;
    }
    if (_toDate!.isBefore(_fromDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be on or after start date')),
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

    final scheduled = ReminderApiMapper.mergeDateAndTime(_fromDate!, _time!);
    if (!_isEdit && scheduled.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start time cannot be in the past')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final existing = widget.initialReminder;
      if (existing != null) {
        await _service.updateMedication(
          id: existing.id,
          caregiverId: caregiverId,
          medicineName: _drugName.text,
          dosage: _dosage.text,
          formUi: _type!,
          frequencyUi: _frequency!,
          timesPerDay: ReminderApiMapper.parseTimesPerDay(_timePerDay.text),
          startDate: _fromDate!,
          endDate: _toDate!,
          time: _time!,
        );
      } else {
        await _service.createMedication(
          caregiverId: caregiverId,
          medicineName: _drugName.text,
          dosage: _dosage.text,
          formUi: _type!,
          frequencyUi: _frequency!,
          timesPerDay: ReminderApiMapper.parseTimesPerDay(_timePerDay.text),
          startDate: _fromDate!,
          endDate: _toDate!,
          time: _time!,
          notifyBefore: _notifyBefore,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _radioGroup({
    required String label,
    required List<String> options,
    required String? groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return LabeledFormField(
      label: label,
      child: RadioGroup<String>(
        groupValue: groupValue,
        onChanged: _submitting ? (_) {} : onChanged,
        child: Wrap(
          children: options
              .map(
                (o) => SizedBox(
                  width: 160,
                  child: RadioListTile<String>(
                    title: Text(o, style: AppTheme.label),
                    value: o,
                    activeColor: AppTheme.primaryColor,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralWhite,
      appBar: ProfileAppBar(
        title: _isEdit ? 'Edit Medicine' : 'Add New Medicine',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          children: [
            LabeledFormField(
              label: 'Drug Name *',
              child: CustomTextFormField(
                controller: _drugName,
                hintText: 'Amlodipine',
                validator: _required,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            LabeledFormField(
              label: 'Dosage *',
              child: CustomTextFormField(
                controller: _dosage,
                hintText: '81 mg – 1 tablet',
                validator: _required,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _radioGroup(
              label: 'Type *',
              options: _types,
              groupValue: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: AppTheme.spacingL),
            _radioGroup(
              label: 'Frequency *',
              options: _frequencies,
              groupValue: _frequency,
              onChanged: (v) => setState(() => _frequency = v),
            ),
            const SizedBox(height: AppTheme.spacingL),
            LabeledFormField(
              label: 'Time Per Day (optional)',
              child: CustomTextFormField(
                controller: _timePerDay,
                hintText: '1',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            LabeledFormField(
              label: 'Time *',
              child: TimePickerField(
                selectedTime: _time,
                onTimeSelected: (t) => setState(() => _time = t),
                hintText: '10:00 AM',
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabeledFormField(
                    label: 'From *',
                    child: DatePickerField(
                      selectedDate: _fromDate,
                      onDateSelected: (d) => setState(() {
                        _fromDate = d;
                        if (_toDate != null && _toDate!.isBefore(d)) {
                          _toDate = null;
                        }
                      }),
                      hintText: 'Select date',
                      dateFormat: DateFormat('dd-MM-yyyy'),
                      firstDate: _fromDateFirstSelectable,
                      lastDate: DateTime(2100),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: LabeledFormField(
                    label: 'To *',
                    child: DatePickerField(
                      selectedDate: _toDate,
                      onDateSelected: (d) => setState(() => _toDate = d),
                      hintText: 'Select date',
                      dateFormat: DateFormat('dd-MM-yyyy'),
                      firstDate: _fromDate ?? _fromDateFirstSelectable,
                      lastDate: DateTime(2100),
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
            if (!_isEdit) const SizedBox(height: AppTheme.spacingXXL),
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
