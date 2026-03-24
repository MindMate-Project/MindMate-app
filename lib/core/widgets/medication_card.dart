import 'package:flutter/material.dart';
import 'package:mindmate/core/widgets/info_pill_card.dart';
import 'package:mindmate/core/themes/app_theme.dart';

class MedicationCard extends StatelessWidget {
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String time;

  const MedicationCard({
    super.key,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final started = 'Started ${_formatDayMonth(startDate)}';
    final end = endDate == null ? '' : ' | End ${_formatDayMonth(endDate!)}';

    return InfoPillCard(
      tag: time,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFFFFF1B8),
              child: Icon(
                Icons.medication_outlined,
                size: 25,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF353535),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dosage | $frequency',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF353535),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$started$end',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.neutralMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatDayMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]}';
  }
}
