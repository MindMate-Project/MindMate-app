import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _sound = true;
  bool _vibration = true;
  bool _reminder1HourBefore = true;
  bool _reminder1DayBefore = true;
  bool _missedDoseAlerts = true;
  bool _dailyMedicineReminders = true;

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
            _buildSection(
              title: 'Common',
              tiles: [
                _NotificationTile(
                  title: 'Push Notifications',
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                _NotificationTile(
                  title: 'Email Notifications',
                  value: _emailNotifications,
                  onChanged: (v) => setState(() => _emailNotifications = v),
                ),
                _NotificationTile(
                  title: 'Sound',
                  value: _sound,
                  onChanged: (v) => setState(() => _sound = v),
                ),
                _NotificationTile(
                  title: 'Vibration',
                  value: _vibration,
                  onChanged: (v) => setState(() => _vibration = v),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            _buildSection(
              title: 'Appointment Notifications',
              tiles: [
                _NotificationTile(
                  title: '1 Hour Before Reminder',
                  value: _reminder1HourBefore,
                  onChanged: (v) => setState(() => _reminder1HourBefore = v),
                ),
                _NotificationTile(
                  title: '1 Day Before Reminder',
                  value: _reminder1DayBefore,
                  onChanged: (v) => setState(() => _reminder1DayBefore = v),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXXL),
            _buildSection(
              title: 'Medication Notifications',
              tiles: [
                _NotificationTile(
                  title: 'Missed Dose Alerts',
                  value: _missedDoseAlerts,
                  onChanged: (v) => setState(() => _missedDoseAlerts = v),
                ),
                _NotificationTile(
                  title: 'Daily Medicine Reminders',
                  value: _dailyMedicineReminders,
                  onChanged: (v) => setState(() => _dailyMedicineReminders = v),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<_NotificationTile> tiles,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.neutralBlack,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Column(
          children: tiles.asMap().entries.map((entry) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(
                    entry.value.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: AppTheme.neutralBlack,
                    ),
                  ),
                  value: entry.value.value,
                  onChanged: entry.value.onChanged,
                  activeTrackColor: AppTheme.primaryColor.withValues(
                    alpha: 0.5,
                  ),
                  activeThumbColor: AppTheme.primaryColor,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _NotificationTile {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });
}
