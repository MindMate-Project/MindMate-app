import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/user_avatar.dart';
import 'package:mindmate/features/assignments/data/models/connected_caregiver.dart';

/// List row for a connected caregiver on the patient profile caregivers screen.
class ConnectedCaregiverCard extends StatelessWidget {
  final ConnectedCaregiver caregiver;
  final VoidCallback onTap;

  const ConnectedCaregiverCard({
    super.key,
    required this.caregiver,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final relationship = caregiver.relationshipLabel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            UserAvatar(
              photoUrl: caregiver.photoUrl,
              name: caregiver.name,
              radius: 25,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caregiver.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  if (relationship != '—') ...[
                    const SizedBox(height: 4),
                    Text(
                      relationship,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
