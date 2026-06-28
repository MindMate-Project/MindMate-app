import 'package:flutter/material.dart';
import 'package:mindmate/core/models/patient_medical_notes.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/info_card.dart';

/// Read-only medical notes block for the patient profile info screen.
class ProfileMedicalNotesSection extends StatelessWidget {
  const ProfileMedicalNotesSection({super.key, required this.notes});

  final PatientMedicalNotes notes;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      tag: 'Medical Notes',
      tagColor: AppTheme.primaryColor,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            'Health Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondaryColor,
            ),
          ),
        ),
        if (notes.isEmpty)
          Text(
            'No medical notes on file.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          )
        else if (notes.freeText != null)
          Text(
            notes.freeText!,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutralDark,
              height: 1.5,
            ),
          )
        else ...[
          _MedicalBullet(label: 'Diagnosis', value: notes.diagnosis),
          _MedicalBullet(label: 'Stage', value: notes.stage),
          _MedicalBullet(
            label: 'Chronic Diseases',
            value: notes.formatList(notes.chronicDiseases),
          ),
          _MedicalBullet(
            label: 'Allergies',
            value: notes.formatList(notes.allergies),
          ),
          _MedicalBullet(
            label: 'Current Medications',
            value: notes.formatList(notes.currentMedication),
          ),
        ],
      ],
    );
  }
}

class _MedicalBullet extends StatelessWidget {
  const _MedicalBullet({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final display = (value?.trim().isEmpty ?? true) ? '—' : value!.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutralDark,
              height: 1.5,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutralDark,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: display),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
