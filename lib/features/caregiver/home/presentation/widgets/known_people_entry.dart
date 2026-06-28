import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/utils/name_utils.dart';
import 'package:mindmate/features/caregiver/home/presentation/models/active_patient.dart';

/// Entry point for caregivers to register faces for the active patient.
class KnownPeopleEntry extends StatelessWidget {
  final ActivePatient patient;

  const KnownPeopleEntry({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final shortName = firstNameOf(patient.name) ?? patient.name;

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.registerKnownPerson,
        extra: {
          'patientId': patient.id,
          'patientName': shortName,
        },
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              child: const Icon(
                Icons.face_retouching_natural,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Faces to recognize',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a person $shortName should recognize',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
