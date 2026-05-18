import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';

class DetailStatTile extends StatelessWidget {
  const DetailStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.neutralLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 22),
          const SizedBox(height: AppTheme.spacingS),
          Text(label, style: AppTheme.label),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.secondaryColor),
          ),
        ],
      ),
    );
  }
}
