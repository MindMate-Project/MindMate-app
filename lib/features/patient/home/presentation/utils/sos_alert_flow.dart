import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/alerts/data/models/patient_alert.dart';
import 'package:mindmate/features/alerts/data/services/alert_service.dart';
import 'package:mindmate/features/assignments/data/models/connected_caregiver.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';

/// Confirmation → backend SOS alert → optional call to the primary caregiver.
class SosAlertFlow {
  SosAlertFlow._();

  static Future<void> start(BuildContext context) async {
    final patientId = _patientId(context);
    if (patientId == null) {
      _showSnack(
        context,
        'Could not identify your account. Please log in again.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.sos, color: AppTheme.errorColor, size: 40),
        title: const Text('Send SOS alert?'),
        content: const Text(
          'Your caregiver will be notified immediately that you need help.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Sending SOS alert…')),
            ],
          ),
        ),
      ),
    );

    ConnectedCaregiver? caregiver;
    String? errorMessage;

    try {
      await AlertService().createAlert(
        patientId: patientId,
        alertType: AlertType.sos.apiValue,
      );
      caregiver = await _loadPrimaryCaregiver(patientId);
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      caregiver = await _loadPrimaryCaregiver(patientId);
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SosResultSheet(
        success: errorMessage == null,
        errorMessage: errorMessage,
        caregiver: caregiver,
      ),
    );
  }

  static String? _patientId(BuildContext context) {
    final state = context.read<AuthCubit>().state;
    if (state is AuthSuccess) {
      return state.user.id;
    }
    return null;
  }

  static Future<ConnectedCaregiver?> _loadPrimaryCaregiver(
    String patientId,
  ) async {
    try {
      final caregivers = await AssignmentService().fetchMyCaregivers(
        patientId: patientId,
      );
      if (caregivers.isEmpty) return null;
      return caregivers.firstWhere(
        (c) => c.hasPhone,
        orElse: () => caregivers.first,
      );
    } catch (_) {
      return null;
    }
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SosResultSheet extends StatefulWidget {
  final bool success;
  final String? errorMessage;
  final ConnectedCaregiver? caregiver;

  const _SosResultSheet({
    required this.success,
    this.errorMessage,
    this.caregiver,
  });

  @override
  State<_SosResultSheet> createState() => _SosResultSheetState();
}

class _SosResultSheetState extends State<_SosResultSheet> {
  bool _calling = false;

  bool get _canCall => !_calling && (widget.caregiver?.hasPhone ?? false);

  String get _callLabel {
    final c = widget.caregiver;
    if (c == null || !c.hasPhone) return 'No caregiver to call';
    return 'Call ${c.firstName}';
  }

  Future<void> _callCaregiver() async {
    final phone = widget.caregiver?.phoneNumber?.trim();
    if (phone == null || phone.isEmpty) return;
    setState(() => _calling = true);
    try {
      final ok = await launchUrl(
        Uri(scheme: 'tel', path: phone),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        SosAlertFlow._showSnack(context, 'Could not open the phone dialer.');
      }
    } catch (_) {
      if (mounted) {
        SosAlertFlow._showSnack(context, 'Could not start the call.');
      }
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final success = widget.success;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              size: 64,
              color: success ? AppTheme.successColor : AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'SOS alert sent' : 'Could not send alert',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (success ? AppTheme.errorColor : AppTheme.warningColor)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (success ? AppTheme.errorColor : AppTheme.warningColor)
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    success
                        ? Icons.notifications_active
                        : Icons.warning_amber_rounded,
                    color: success
                        ? AppTheme.errorColor
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      success
                          ? 'Your caregiver has been notified. If you need '
                                'immediate help, call them now.'
                          : widget.errorMessage ??
                                'Something went wrong. Try again or call your '
                                    'caregiver directly.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canCall ? _callCaregiver : null,
                icon: _calling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.call, color: Colors.white, size: 20),
                label: Text(
                  _callLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  disabledBackgroundColor: AppTheme.neutralMedium,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
