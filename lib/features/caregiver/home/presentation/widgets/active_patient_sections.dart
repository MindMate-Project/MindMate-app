import 'package:flutter/material.dart';
import 'package:mindmate/features/caregiver/home/presentation/models/active_patient.dart';
import 'package:mindmate/features/caregiver/home/presentation/widgets/known_people_entry.dart';
import 'package:mindmate/features/location/presentation/widgets/location_section.dart';
import 'package:mindmate/features/patient/reminders/presentation/widgets/home_reminders_section.dart';

/// Patient-scoped dashboard blocks shown on the caregiver home screen.
///
/// Keyed by [ActivePatient.id] at the call site so switching patients resets
/// every section widget tree.
class ActivePatientSections extends StatelessWidget {
  final ActivePatient patient;

  const ActivePatientSections({super.key, required this.patient});

  static const _sectionGap = 30.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LocationSection(patient: patient),
        const SizedBox(height: _sectionGap),
        KnownPeopleEntry(patient: patient),
        const SizedBox(height: _sectionGap),
        const HomeRemindersSection(),
      ],
    );
  }
}
