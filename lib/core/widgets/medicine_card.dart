import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';

class MedicineCard extends StatelessWidget {
  final String name;
  final String dosage;
  final String frequency;
  final String time;
  final String startDate;
  final String endDate;

  const MedicineCard({
    super.key,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.neutralLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Medicine icon
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3CD),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/images/medicine_icon.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.medication_outlined,
                      color: Color(0xFF4A9EC0),
                      size: 30,
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Medicine details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row with time badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF353535),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Dosage and frequency
                Text(
                  '$dosage | $frequency',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF353535),
                  ),
                ),

                const SizedBox(height: 4),

                // Date range
                Text(
                  'Started $startDate | End $endDate',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
