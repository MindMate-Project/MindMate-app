import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';

class InfoMessageBox extends StatelessWidget {
  const InfoMessageBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.neutralLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: AppTheme.neutralDark)),
    );
  }
}
