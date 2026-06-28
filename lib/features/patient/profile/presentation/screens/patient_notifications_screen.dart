import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminder_notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PatientNotificationsScreen extends StatefulWidget {
  const PatientNotificationsScreen({super.key});

  @override
  State<PatientNotificationsScreen> createState() =>
      _PatientNotificationsScreenState();
}

class _PatientNotificationsScreenState extends State<PatientNotificationsScreen>
    with WidgetsBindingObserver {
  bool _showAlarmLimitBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshAlarmBanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAlarmBanner();
    }
  }

  Future<void> _refreshAlarmBanner() async {
    if (!mounted) return;
    if (kIsWeb || !Platform.isAndroid) {
      setState(() => _showAlarmLimitBanner = false);
      return;
    }

    final version = Platform.operatingSystemVersion;
    final match = RegExp(r'(\d+)').firstMatch(version);
    final major = match != null ? int.tryParse(match.group(1)!) : null;
    if (major == null || major < 14) {
      setState(() => _showAlarmLimitBanner = false);
      return;
    }

    final granted =
        await ReminderNotificationService.instance.hasFullScreenIntentPermission();
    if (!mounted) return;
    setState(() => _showAlarmLimitBanner = !granted);
  }

  Future<void> _fixAlarmPermissions() async {
    await ReminderNotificationService.instance.requestFullScreenIntentAccess();
    await openAppSettings();
    await _refreshAlarmBanner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const ProfileAppBar(title: 'Notification'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacingXL),
            if (_showAlarmLimitBanner) ...[
              Material(
                color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: InkWell(
                  onTap: _fixAlarmPermissions,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: Text(
                            'Alarm notifications are limited — tap to fix in settings.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: AppTheme.neutralBlack.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppTheme.secondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
            ],
            Text(
              'Reminder and alert notifications are managed automatically by MindMate.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppTheme.neutralBlack.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Manage Notification Permissions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutralBlack,
                ),
              ),
              subtitle: const Text(
                'Open your device settings to allow or adjust push notifications.',
                style: TextStyle(fontSize: 13),
              ),
              trailing:
                  const Icon(Icons.open_in_new, color: AppTheme.primaryColor),
              onTap: () => openAppSettings(),
            ),
            const SizedBox(height: AppTheme.spacingXXL),
          ],
        ),
      ),
    );
  }
}
