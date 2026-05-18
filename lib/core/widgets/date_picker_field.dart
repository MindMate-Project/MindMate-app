import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../themes/app_theme.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final String? hintText;
  final DateFormat? dateFormat;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.hintText,
    this.dateFormat,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final format = dateFormat ?? DateFormat('MM/dd/yyyy');
    final first = firstDate ?? DateTime(1900);
    final last = lastDate ?? DateTime.now();
    final initial = selectedDate ?? DateTime.now();
    final clampedInitial = initial.isBefore(first)
        ? first
        : initial.isAfter(last)
            ? last
            : initial;

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: clampedInitial,
          firstDate: first,
          lastDate: last,
        );
        if (date != null) onDateSelected(date);
      },
      child: InputDecorator(
        decoration: pickerDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate == null
                  ? (hintText ?? 'Select date')
                  : format.format(selectedDate!),
              style: AppTheme.hintText,
            ),
            const Icon(Icons.calendar_today, color: AppTheme.neutralMedium),
          ],
        ),
      ),
    );
  }

  static final InputDecoration pickerDecoration = InputDecoration(
    filled: true,
    fillColor: AppTheme.backgroundWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: const BorderSide(color: AppTheme.neutralMedium),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1),
    ),
  );
}

class TimePickerField extends StatelessWidget {
  const TimePickerField({
    super.key,
    required this.selectedTime,
    required this.onTimeSelected,
    this.hintText,
  });

  final TimeOfDay? selectedTime;
  final ValueChanged<TimeOfDay> onTimeSelected;
  final String? hintText;

  static String _format(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
        );
        if (time != null) onTimeSelected(time);
      },
      child: InputDecorator(
        decoration: DatePickerField.pickerDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedTime == null
                  ? (hintText ?? 'Select time')
                  : _format(selectedTime!),
              style: AppTheme.hintText,
            ),
            const Icon(Icons.schedule, color: AppTheme.neutralMedium),
          ],
        ),
      ),
    );
  }
}
