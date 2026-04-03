import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';

class WeeklyCalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const WeeklyCalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return EasyDateTimeLine(
      initialDate: selectedDate,
      onDateChange: onDateSelected,
      headerProps: const EasyHeaderProps(
        monthPickerType: MonthPickerType.switcher,
        dateFormatter: DateFormatter.fullDateMonthAsStrDY(),
        selectedDateStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: AppTheme.neutralDark,
        ),
      ),
      dayProps: EasyDayProps(
        height: 85,
        width: 60,
        dayStructure: DayStructure.dayStrDayNum,
        // Style for the selected day
        activeDayStyle: DayStyle(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: AppTheme.neutralSkyBlue,
          ),
          dayNumStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          dayStrStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
        // Style for unselected days
        inactiveDayStyle: DayStyle(
          dayNumStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.neutralDark,
          ),
          dayStrStyle: TextStyle(fontSize: 12, color: AppTheme.neutralMedium),
          decoration: BoxDecoration(
            border: BoxBorder.all(color: Colors.transparent),
          ),
        ),
      ),
    );
  }
}
