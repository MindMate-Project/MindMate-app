import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/error_retry_view.dart';
import 'package:mindmate/core/widgets/info_card.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/caregiver/patients/data/models/caregiver_patient_detail.dart';
import 'package:mindmate/features/caregiver/patients/data/services/device_service.dart';
import 'package:mindmate/features/caregiver/patients/presentation/cubit/patient_detail_cubit.dart';
import 'package:mindmate/features/caregiver/patients/presentation/cubit/patient_detail_state.dart';
import 'package:mindmate/features/caregiver/patients/presentation/screens/edit_patient_screen.dart';
import 'package:mindmate/features/caregiver/patients/presentation/widgets/patient_detail_widgets.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PatientDetailCubit(
        AssignmentService(),
        DeviceService(),
        widget.patientId,
      )..load(),
      child: const _PatientDetailView(),
    );
  }
}

class _PatientDetailView extends StatelessWidget {
  const _PatientDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: const ProfileAppBar(title: 'Patient Details'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<PatientDetailCubit, PatientDetailState>(
                builder: (context, state) {
                  return switch (state) {
                    PatientDetailInitial() ||
                    PatientDetailLoading() => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    PatientDetailError(:final message) => ErrorRetryView(
                      message: message,
                      onRetry: () => context.read<PatientDetailCubit>().load(),
                    ),
                    PatientDetailLoaded(:final patient) ||
                    PatientDetailDeleting(:final patient) ||
                    PatientDetailAssigningDevice(
                      :final patient,
                    ) => _PatientDetailBody(
                      patient: patient,
                      deleting: state is PatientDetailDeleting,
                      assigningDevice: state is PatientDetailAssigningDevice,
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientDetailBody extends StatelessWidget {
  final CaregiverPatientDetail patient;
  final bool deleting;
  final bool assigningDevice;

  const _PatientDetailBody({
    required this.patient,
    required this.deleting,
    required this.assigningDevice,
  });

  String _orDash(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '—' : trimmed;
  }

  Future<void> _openEdit(BuildContext context) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => EditPatientScreen(patient: patient),
      ),
    );
    if (updated == true && context.mounted) {
      await context.read<PatientDetailCubit>().load();
    }
  }

  Future<void> _showAssignDeviceDialog(BuildContext context) async {
    final assigned = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _AssignDeviceDialog(
        initialDeviceId: patient.device.deviceId,
        patientEmail: patient.email ?? 'this patient',
        hasDevice: patient.device.hasDevice,
      ),
    );
    if (assigned == null || !context.mounted) return;

    try {
      await context.read<PatientDetailCubit>().assignDevice(assigned);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device assigned successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = deleting || assigningDevice;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PatientProfileSummaryCard(
                  name: patient.name,
                  age: patient.age,
                  photoUrl: patient.photoUrl,
                ),
                const SizedBox(height: 16),
                _ContactCard(patient: patient, orDash: _orDash),
                const SizedBox(height: 8),
                _DeviceCard(
                  patient: patient,
                  orDash: _orDash,
                  assigning: assigningDevice,
                  onAssign: busy
                      ? null
                      : () => _showAssignDeviceDialog(context),
                ),
                const SizedBox(height: 8),
                _MedicalNotesCard(patient: patient),
              ],
            ),
          ),
        ),
        _ActionBar(
          deleting: deleting,
          onEdit: busy ? null : () => _openEdit(context),
        ),
      ],
    );
  }
}

class _AssignDeviceDialog extends StatefulWidget {
  final String? initialDeviceId;
  final String patientEmail;
  final bool hasDevice;

  const _AssignDeviceDialog({
    required this.initialDeviceId,
    required this.patientEmail,
    required this.hasDevice,
  });

  @override
  State<_AssignDeviceDialog> createState() => _AssignDeviceDialogState();
}

class _AssignDeviceDialogState extends State<_AssignDeviceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDeviceId ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.hasDevice ? 'Change Device' : 'Add Device'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned to ${widget.patientEmail}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Device ID',
              hintText: 'e.g. ESP32-001',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final id = _controller.text.trim();
            if (id.isEmpty) return;
            Navigator.pop(context, id);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text('Assign'),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final CaregiverPatientDetail patient;
  final String Function(String?) orDash;

  const _ContactCard({required this.patient, required this.orDash});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.neutralLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          PatientDetailInfoRow(
            icon: Icons.phone_outlined,
            value: orDash(patient.phoneNumber),
          ),
          PatientDetailInfoRow(
            icon: Icons.location_on_outlined,
            value: orDash(patient.address),
          ),
          PatientDetailInfoRow(
            icon: Icons.favorite_border,
            value: patient.relationshipLabel,
          ),
          PatientDetailInfoRow(
            icon: Icons.person_outline,
            value: orDash(patient.gender),
          ),
          PatientDetailInfoRow(
            icon: Icons.email_outlined,
            value: orDash(patient.email),
          ),
          if (patient.formattedDateOfBirth != null)
            PatientDetailInfoRow(
              icon: Icons.cake_outlined,
              value: patient.formattedDateOfBirth!,
            ),
          if (patient.formattedConnectedAt != null)
            PatientDetailInfoRow(
              icon: Icons.link_outlined,
              value: 'Connected ${patient.formattedConnectedAt}',
            ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final CaregiverPatientDetail patient;
  final String Function(String?) orDash;
  final bool assigning;
  final VoidCallback? onAssign;

  const _DeviceCard({
    required this.patient,
    required this.orDash,
    required this.assigning,
    this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      tag: 'Device',
      tagColor: AppTheme.secondaryColor,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            'Tracking Device',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondaryColor,
            ),
          ),
        ),
        if (patient.device.hasDevice) ...[
          PatientDetailInfoRow(
            icon: Icons.sensors_outlined,
            value: orDash(patient.device.deviceId),
          ),
          if (patient.formattedDeviceLastSeen != null)
            PatientDetailInfoRow(
              icon: Icons.access_time_outlined,
              value: 'Last seen ${patient.formattedDeviceLastSeen}',
            ),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No tracking device assigned yet.',
              style: TextStyle(fontSize: 14, color: AppTheme.neutralDark),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: assigning ? null : onAssign,
            icon: assigning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    patient.device.hasDevice
                        ? Icons.swap_horiz
                        : Icons.add_circle_outline,
                  ),
            label: Text(
              patient.device.hasDevice ? 'Change Device' : 'Add Device',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MedicalNotesCard extends StatelessWidget {
  final CaregiverPatientDetail patient;

  const _MedicalNotesCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final notes = patient.medicalNotes;

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
        if (notes.freeText != null)
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
  final String label;
  final String? value;

  const _MedicalBullet({required this.label, this.value});

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

class _ActionBar extends StatelessWidget {
  final bool deleting;
  final VoidCallback? onEdit;

  const _ActionBar({required this.deleting, this.onEdit});

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove patient'),
        content: const Text(
          'This will disconnect you from this patient. You can send a new '
          'assignment request later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final removed = await context.read<PatientDetailCubit>().deletePatient();
      if (!context.mounted || !removed) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: deleting ? null : onEdit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Edit'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: deleting ? null : () => _confirmDelete(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }
}
