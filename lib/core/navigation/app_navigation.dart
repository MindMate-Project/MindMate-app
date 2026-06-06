import 'package:flutter/material.dart';
import 'package:mindmate/features/patient/reminders/presentation/screens/reminder_alarm_screen.dart';

/// Global key for the app's root [Navigator], used to drive navigation from
/// outside the widget tree (notification taps, reminder alarms).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// The reminder currently showing its full-screen alarm, so the same alarm
/// isn't pushed twice (e.g. a tap callback racing a cold-start launch).
String? _activeAlarmReminderId;

/// Pushes the full-screen [ReminderAlarmScreen] on the root navigator, retrying
/// until the navigator is mounted. Safe to call from notification callbacks and
/// from the splash once it has resolved (and navigated to) the start route.
void showReminderAlarm(int notificationId, String reminderId) {
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) {
    Future.delayed(
      const Duration(milliseconds: 250),
      () => showReminderAlarm(notificationId, reminderId),
    );
    return;
  }
  if (_activeAlarmReminderId == reminderId) return;
  _activeAlarmReminderId = reminderId;
  navigator
      .push(
        MaterialPageRoute<void>(
          builder: (_) => ReminderAlarmScreen(
            notificationId: notificationId,
            reminderId: reminderId,
          ),
        ),
      )
      .whenComplete(() {
    if (_activeAlarmReminderId == reminderId) _activeAlarmReminderId = null;
  });
}
