import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../themes/app_theme.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;
  final String? hintText;
  final DateFormat? dateFormat;

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.hintText,
    this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final format = dateFormat ?? DateFormat('MM/dd/yyyy');
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
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
        ),
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
}
