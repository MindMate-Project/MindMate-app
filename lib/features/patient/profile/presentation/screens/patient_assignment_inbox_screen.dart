import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/info_card.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/assignments/data/models/pending_caregiver_request.dart';
import 'package:mindmate/features/assignments/presentation/cubit/patient_assignment_requests_cubit.dart';
import 'package:mindmate/features/assignments/presentation/cubit/patient_assignment_requests_state.dart';

class PatientAssignmentInboxScreen extends StatefulWidget {
  const PatientAssignmentInboxScreen({super.key});

  @override
  State<PatientAssignmentInboxScreen> createState() => _PatientAssignmentInboxScreenState();
}

class _PatientAssignmentInboxScreenState extends State<PatientAssignmentInboxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PatientAssignmentRequestsCubit>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const ProfileAppBar(title: 'Caregiver requests'),
      body: BlocConsumer<PatientAssignmentRequestsCubit, PatientAssignmentRequestsState>(
        listenWhen: (p, c) => p.errorMessage != c.errorMessage && c.errorMessage != null,
        listener: (context, state) {
          final msg = state.errorMessage;
          if (msg != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        builder: (context, state) {
          if (state.status == PatientAssignmentLoadStatus.loading && state.requests.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (state.status == PatientAssignmentLoadStatus.failure && state.requests.isEmpty) {
            return _ErrorBody(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () => context.read<PatientAssignmentRequestsCubit>().refresh(),
            );
          }
          return RefreshIndicator(
            color: AppTheme.primaryColor,
            onRefresh: () => context.read<PatientAssignmentRequestsCubit>().refresh(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL, vertical: AppTheme.spacingM),
              children: [
                InfoCard(
                  tag: 'Info',
                  tagColor: AppTheme.primaryColor,
                  children: [
                    Text(
                      'When a caregiver asks to connect, their request appears here. '
                      'You can accept or decline. They only get access after you accept.',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
                if (state.requests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        'No pending requests',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                      ),
                    ),
                  )
                else
                  ...state.requests.map((r) => _RequestCard(request: r)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: AppTheme.bodyMedium),
            const SizedBox(height: AppTheme.spacingL),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final PendingCaregiverRequest request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final dateStr = r.requestedAt != null
        ? DateFormat.yMMMd().add_jm().format(r.requestedAt!.toLocal())
        : null;
    final relLabel = r.relationship?.label ?? 'Relationship pending';
    final cubit = context.read<PatientAssignmentRequestsCubit>();
    final state = context.watch<PatientAssignmentRequestsCubit>().state;
    final busy = state.actingOnCaregiverId == r.caregiverId;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      elevation: 0,
      color: AppTheme.neutralLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.caregiverName, style: AppTheme.heading3.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text(relLabel, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
            if (r.caregiverEmail != null) ...[
              const SizedBox(height: 8),
              Text(r.caregiverEmail!, style: AppTheme.bodyMedium),
            ],
            if (dateStr != null) ...[
              const SizedBox(height: 4),
              Text('Requested $dateStr', style: AppTheme.bodySmall),
            ],
            const SizedBox(height: AppTheme.spacingM),
            if (busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => cubit.respond(caregiverId: r.caregiverId, accept: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xffEB4335),
                        side: const BorderSide(color: Color(0xffEB4335)),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => cubit.respond(caregiverId: r.caregiverId, accept: true),
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
