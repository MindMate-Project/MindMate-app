import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/info_card.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/alerts/data/models/alert_list_item.dart';
import 'package:mindmate/features/alerts/data/models/patient_alert.dart';
import 'package:mindmate/features/alerts/presentation/cubit/alert_cubit.dart';
import 'package:mindmate/features/alerts/presentation/cubit/alert_state.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';

/// Caregiver activity: patient alerts from the API.
class CaregiverNotificationsScreen extends StatelessWidget {
  const CaregiverNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlertCubit()..loadAlerts(),
      child: const _CaregiverNotificationsView(),
    );
  }
}

class _CaregiverNotificationsView extends StatefulWidget {
  const _CaregiverNotificationsView();

  @override
  State<_CaregiverNotificationsView> createState() =>
      _CaregiverNotificationsViewState();
}

class _CaregiverNotificationsViewState
    extends State<_CaregiverNotificationsView> {
  String? _acknowledgingId;

  Future<void> _acknowledge(String alertId) async {
    final authState = context.read<AuthCubit>().state;
    final caregiverId = authState is AuthSuccess ? authState.user.id : null;
    if (caregiverId == null || caregiverId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not identify caregiver account.')),
        );
      }
      return;
    }

    setState(() => _acknowledgingId = alertId);
    try {
      await context.read<AlertCubit>().acknowledgeAlert(alertId, caregiverId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _acknowledgingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const ProfileAppBar(title: 'Notifications'),
      body: BlocConsumer<AlertCubit, AlertState>(
        listener: (context, state) {
          if (state is AlertError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AlertLoading || state is AlertInitial) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              ],
            );
          }

          if (state is AlertError) {
            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () => context.read<AlertCubit>().loadAlerts(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXL,
                  vertical: AppTheme.spacingM,
                ),
                children: [
                  const SizedBox(height: 120),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is AlertLoaded) {
            final pendingAlerts = state.alerts
                .where((entry) => !entry.alert.isAcknowledged)
                .toList();
            final acknowledgedAlerts = state.alerts
                .where((entry) => entry.alert.isAcknowledged)
                .toList();

            return RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () => context.read<AlertCubit>().loadAlerts(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingXL,
                  vertical: AppTheme.spacingM,
                ),
                children: [
                  InfoCard(
                    tag: 'Info',
                    tagColor: AppTheme.infoColor,
                    children: [
                      Text(
                        'Safe zone and SOS alerts appear here. Set safe zones on '
                        'the Location tab to get notified when a patient leaves.',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  if (pendingAlerts.isNotEmpty) ...[
                    Text(
                      'Active alerts',
                      style: AppTheme.heading3.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    ...pendingAlerts.map(
                      (entry) => _AlertCard(
                        entry: entry,
                        acknowledging: _acknowledgingId == entry.alert.id,
                        onAcknowledge: () => _acknowledge(entry.alert.id),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                  ],
                  if (acknowledgedAlerts.isNotEmpty) ...[
                    Text(
                      'Past alerts',
                      style: AppTheme.heading3.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    ...acknowledgedAlerts.map(
                      (entry) => _AlertCard(
                        entry: entry,
                        acknowledging: false,
                      ),
                    ),
                  ],
                  if (state.alerts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'No alerts yet.',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertListItem entry;
  final bool acknowledging;
  final VoidCallback? onAcknowledge;

  const _AlertCard({
    required this.entry,
    required this.acknowledging,
    this.onAcknowledge,
  });

  Color get _tagColor {
    if (entry.alert.isAcknowledged) return AppTheme.neutralMedium;
    switch (entry.alert.type) {
      case AlertType.geofence:
        return AppTheme.warningColor;
      case AlertType.sos:
        return AppTheme.errorColor;
      case AlertType.unknown:
        return AppTheme.infoColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final when = DateFormat.yMMMd().add_jm().format(entry.alert.timestamp);

    return InfoCard(
      tag: entry.alert.isAcknowledged ? 'Acknowledged' : 'New',
      tagColor: _tagColor,
      children: [
        Text(
          entry.alert.displayTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text('Patient: ${entry.patientName}', style: AppTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(when, style: AppTheme.bodySmall),
        if (!entry.alert.isAcknowledged && onAcknowledge != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: acknowledging ? null : onAcknowledge,
              child: acknowledging
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Acknowledge'),
            ),
          ),
        ],
      ],
    );
  }
}
