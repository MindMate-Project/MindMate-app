import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/error_retry_view.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/core/widgets/user_avatar.dart';
import 'package:mindmate/features/assignments/data/models/connected_caregiver.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/caregiver/patients/presentation/widgets/patient_detail_widgets.dart';
import 'package:mindmate/features/patient/profile/presentation/cubit/patient_caregiver_detail_cubit.dart';
import 'package:mindmate/features/patient/profile/presentation/cubit/patient_caregiver_detail_state.dart';

class PatientCaregiverDetailScreen extends StatelessWidget {
  final String caregiverId;

  const PatientCaregiverDetailScreen({super.key, required this.caregiverId});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final patientId = authState is AuthSuccess ? (authState.user.id ?? '') : '';

    return BlocProvider(
      create: (_) => PatientCaregiverDetailCubit(
        AssignmentService(),
        caregiverId: caregiverId,
        patientId: patientId,
      )..load(),
      child: const _PatientCaregiverDetailView(),
    );
  }
}

class _PatientCaregiverDetailView extends StatelessWidget {
  const _PatientCaregiverDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            const ProfileAppBar(title: 'Caregiver Details'),
            Expanded(
              child:
                  BlocBuilder<
                    PatientCaregiverDetailCubit,
                    PatientCaregiverDetailState
                  >(
                    builder: (context, state) {
                      return switch (state) {
                        PatientCaregiverDetailInitial() ||
                        PatientCaregiverDetailLoading() => const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        PatientCaregiverDetailError(:final message) =>
                          ErrorRetryView(
                            message: message,
                            onRetry: () => context
                                .read<PatientCaregiverDetailCubit>()
                                .load(),
                          ),
                        PatientCaregiverDetailLoaded(:final caregiver) ||
                        PatientCaregiverDetailDeleting(
                          :final caregiver,
                        ) => _CaregiverDetailBody(
                          caregiver: caregiver,
                          removing: state is PatientCaregiverDetailDeleting,
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

class _CaregiverDetailBody extends StatelessWidget {
  final ConnectedCaregiver caregiver;
  final bool removing;

  const _CaregiverDetailBody({required this.caregiver, required this.removing});

  String _orDash(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? '—' : trimmed;
  }

  String _connectedLabel() {
    final date = caregiver.connectedAt;
    if (date == null) return '—';
    return DateFormat.yMMMd().format(date.toLocal());
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove caregiver'),
        content: Text(
          'Remove ${caregiver.name} from your care network? They will no longer '
          'be able to manage your reminders or memories.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final removed = await context
          .read<PatientCaregiverDetailCubit>()
          .removeCaregiver();
      if (!context.mounted || !removed) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Caregiver removed')));
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CaregiverSummaryCard(caregiver: caregiver),
                const SizedBox(height: 16),
                _ContactCard(
                  caregiver: caregiver,
                  orDash: _orDash,
                  connectedLabel: _connectedLabel(),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: FilledButton(
            onPressed: removing ? null : () => _confirmRemove(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.all(14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: removing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Remove caregiver'),
          ),
        ),
      ],
    );
  }
}

class _CaregiverSummaryCard extends StatelessWidget {
  final ConnectedCaregiver caregiver;

  const _CaregiverSummaryCard({required this.caregiver});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          UserAvatar(
            photoUrl: caregiver.photoUrl,
            name: caregiver.name,
            radius: 36,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caregiver.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  caregiver.relationshipLabel,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final ConnectedCaregiver caregiver;
  final String Function(String?) orDash;
  final String connectedLabel;

  const _ContactCard({
    required this.caregiver,
    required this.orDash,
    required this.connectedLabel,
  });

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
            icon: Icons.email_outlined,
            value: orDash(caregiver.email),
          ),
          PatientDetailInfoRow(
            icon: Icons.phone_outlined,
            value: orDash(caregiver.phoneNumber),
          ),
          PatientDetailInfoRow(
            icon: Icons.location_on_outlined,
            value: orDash(caregiver.address),
          ),
          PatientDetailInfoRow(
            icon: Icons.wc_outlined,
            value: caregiver.genderLabel,
          ),
          PatientDetailInfoRow(
            icon: Icons.people_outline,
            value: caregiver.relationshipLabel,
          ),
          PatientDetailInfoRow(
            icon: Icons.calendar_today_outlined,
            value: 'Connected $connectedLabel',
          ),
        ],
      ),
    );
  }
}
