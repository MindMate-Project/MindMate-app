import 'package:flutter/material.dart';
import 'package:mindmate/core/widgets/info_card.dart';
import 'package:mindmate/core/themes/app_theme.dart';

class AppointmentCard extends StatelessWidget {
  final String doctorName, specialty, location, date, time, type;

  const AppointmentCard({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.location,
    required this.date,
    required this.time,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      tag: type,
      children: [
        Text(doctorName, style: _titleStyle),
        const SizedBox(height: 6),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(specialty, style: _subStyle),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('|', style: TextStyle(color: Colors.grey)),
            ),
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(location, style: _subStyle),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(date, style: _detailStyle),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('|', style: TextStyle(color: Colors.grey)),
            ),
            const Icon(
              Icons.access_time,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(time, style: _detailStyle),
          ],
        ),
      ],
    );
  }

  static const _titleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xFF353535),
  );
  static const _subStyle = TextStyle(fontSize: 15, color: Color(0xFF353535));
  static const _detailStyle = TextStyle(
    fontSize: 15,
    color: AppTheme.neutralMedium,
  );
}
