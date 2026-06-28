import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/core/services/caregiver_notification_preferences.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/info_card.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/alerts/data/models/alert_list_item.dart';
import 'package:mindmate/features/alerts/data/models/patient_alert.dart';
import 'package:mindmate/features/alerts/presentation/cubit/alert_cubit.dart';
import 'package:mindmate/features/alerts/presentation/cubit/alert_state.dart';

/// Caregiver activity: patient alerts from the API.
class CaregiverNotificationsScreen extends StatelessWidget {
  const CaregiverNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CaregiverNotificationsView();
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
  String? _deletingId;
  bool _bulkAcknowledging = false;
  bool _bulkDeleting = false;

  final _prefs = CaregiverNotificationPreferences.instance;

  bool get _bulkBusy => _bulkAcknowledging || _bulkDeleting;

  @override
  void initState() {
    super.initState();
    _prefs.revision.addListener(_onPrefsChanged);
    context.read<AlertCubit>().loadAlerts();
  }

  @override
  void dispose() {
    _prefs.revision.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    if (mounted) setState(() {});
  }

  Widget _buildFlutterSideAlertsToggle() {
    final enabled = _prefs.flutterSideAlertsEnabled;

    return InfoCard(
      tag: 'Testing',
      tagColor: AppTheme.primaryColor,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Flutter-side alerts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryColor,
            ),
          ),
          subtitle: Text(
            enabled
                ? 'On: safe-zone exits are detected in the app and shown as '
                    'local notifications and banners.'
                : 'Off: Flutter workarounds are disabled. Alerts should arrive '
                    'only via Firebase push from the server.',
            style: AppTheme.bodySmall,
          ),
          value: enabled,
          activeThumbColor: AppTheme.primaryColor,
          onChanged: (value) =>
              _prefs.setFlutterSideAlertsEnabled(value),
        ),
      ],
    );
  }

  Future<void> _acknowledge(String alertId) async {
    setState(() => _acknowledgingId = alertId);
    try {
      await context.read<AlertCubit>().acknowledgeAlert(alertId);
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

  Future<void> _confirmDelete(AlertListItem entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete alert?'),
        content: Text(
          'Permanently remove this ${entry.alert.displayTitle.toLowerCase()} '
          'alert for ${entry.patientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = entry.alert.id);
    try {
      await context.read<AlertCubit>().deleteAlert(entry.alert.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _confirmAcknowledgeAll(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark all as read?'),
        content: Text(
          'Acknowledge all $count active alert${count == 1 ? '' : 's'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Read all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _bulkAcknowledging = true);
    try {
      await context.read<AlertCubit>().acknowledgeAllAlerts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _bulkAcknowledging = false);
    }
  }

  Future<void> _confirmDeleteAllAcknowledged(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all past alerts?'),
        content: Text(
          'Permanently remove all $count acknowledged alert${count == 1 ? '' : 's'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _bulkDeleting = true);
    try {
      await context.read<AlertCubit>().deleteAllAcknowledgedAlerts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _bulkDeleting = false);
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXL,
                vertical: AppTheme.spacingM,
              ),
              children: [
                _buildFlutterSideAlertsToggle(),
                const SizedBox(height: AppTheme.spacingL),
                const SizedBox(height: 120),
                const Center(
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
                  _buildFlutterSideAlertsToggle(),
                  const SizedBox(height: AppTheme.spacingL),
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
                  _buildFlutterSideAlertsToggle(),
                  const SizedBox(height: AppTheme.spacingL),
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
                    _SectionHeader(
                      title: 'Active alerts',
                      actionLabel: 'Read all',
                      actionLoading: _bulkAcknowledging,
                      onAction: _bulkBusy
                          ? null
                          : () => _confirmAcknowledgeAll(pendingAlerts.length),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    ...pendingAlerts.map(
                      (entry) => _AlertCard(
                        entry: entry,
                        acknowledging: _acknowledgingId == entry.alert.id,
                        deleting: _deletingId == entry.alert.id,
                        actionsDisabled: _bulkBusy,
                        onAcknowledge: () => _acknowledge(entry.alert.id),
                        onDelete: () => _confirmDelete(entry),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                  ],
                  if (acknowledgedAlerts.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Past alerts',
                      actionLabel: 'Delete all',
                      actionLoading: _bulkDeleting,
                      actionColor: AppTheme.errorColor,
                      onAction: _bulkBusy
                          ? null
                          : () => _confirmDeleteAllAcknowledged(
                                acknowledgedAlerts.length,
                              ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    ...acknowledgedAlerts.map(
                      (entry) => _AlertCard(
                        entry: entry,
                        acknowledging: false,
                        deleting: _deletingId == entry.alert.id,
                        actionsDisabled: _bulkBusy,
                        onDelete: () => _confirmDelete(entry),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.actionLoading,
    this.actionColor,
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final bool actionLoading;
  final Color? actionColor;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTheme.heading3.copyWith(fontSize: 18),
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: actionLoading ? null : onAction,
            style: actionColor != null
                ? TextButton.styleFrom(foregroundColor: actionColor)
                : null,
            child: actionLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(actionLabel),
          ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertListItem entry;
  final bool acknowledging;
  final bool deleting;
  final bool actionsDisabled;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onDelete;

  const _AlertCard({
    required this.entry,
    required this.acknowledging,
    this.deleting = false,
    this.actionsDisabled = false,
    this.onAcknowledge,
    this.onDelete,
  });

  Color get _tagColor {
    if (entry.alert.isAcknowledged) return AppTheme.neutralMedium;
    switch (entry.alert.type) {
      case AlertType.locationOutOfBounds:
      case AlertType.sos:
        return AppTheme.errorColor;
      case AlertType.deviceOffline:
        return AppTheme.warningColor;
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
        if (onAcknowledge != null || onDelete != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!entry.alert.isAcknowledged && onAcknowledge != null)
                TextButton(
                  onPressed: actionsDisabled || acknowledging || deleting
                      ? null
                      : onAcknowledge,
                  child: acknowledging
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Acknowledge'),
                ),
              if (onDelete != null)
                TextButton(
                  onPressed: actionsDisabled || acknowledging || deleting
                      ? null
                      : onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                  child: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Delete'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
