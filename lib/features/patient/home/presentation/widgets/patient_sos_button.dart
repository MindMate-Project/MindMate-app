import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/patient/home/presentation/utils/sos_alert_flow.dart';

/// Large, high-contrast SOS control for the patient home screen.
class PatientSosButton extends StatelessWidget {
  const PatientSosButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      shadowColor: AppTheme.errorColor.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(24),
      color: AppTheme.errorColor,
      child: InkWell(
        onTap: () => SosAlertFlow.start(context),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.sos, color: Colors.white, size: 40),
              ),
              const SizedBox(width: 18),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        height: 1,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tap for emergency help',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Alerts your caregiver instantly',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
