import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';
import 'package:mindmate/features/patient/reminders/data/utils/reminder_filters.dart';
import 'package:mindmate/features/patient/reminders/presentation/utils/reminder_formatters.dart';

/// Full-screen, alarm-style reminder. Shown when a medication/appointment
/// reminder fires (launched over the lock screen by its full-screen intent, or
/// pushed when the app is already running). It rings the bundled alarm tone on
/// a loop with continuous vibration and can **only** be silenced by pressing the
/// acknowledge button — there is no snooze, so it can't be postponed-and-forgotten.
class ReminderAlarmScreen extends StatefulWidget {
  const ReminderAlarmScreen({
    super.key,
    required this.notificationId,
    required this.reminderId,
  });

  /// The numeric id of the OS notification, used to clear it on dismiss.
  final int notificationId;

  /// The reminder's id, used to load its details (medicine/appointment).
  final String reminderId;

  @override
  State<ReminderAlarmScreen> createState() => _ReminderAlarmScreenState();
}

class _ReminderAlarmScreenState extends State<ReminderAlarmScreen> {
  final AudioPlayer _player = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final RemindersService _service = RemindersService();

  Timer? _vibrate;
  Timer? _clock;
  ReminderItem? _item;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _startRinging();
    _loadReminder();
    // Live clock for the alarm-style time readout.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _startRinging() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Route the loop through the alarm stream (alarm volume) and keep a wake
      // lock so it keeps ringing even if the screen sleeps. WAKE_LOCK is already
      // declared in the manifest.
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.duckOthers},
          ),
        ),
      );
      await _player.play(AssetSource('sounds/alarm.wav'), volume: 1.0);
    } catch (e) {
      // The OS notification still played the alarm-channel sound; keep the
      // screen up even if the looping tone fails to start.
      debugPrint('[ReminderAlarm] audio failed: $e');
    }

    // Continuous vibration without pulling in an extra package.
    HapticFeedback.heavyImpact();
    _vibrate = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      HapticFeedback.heavyImpact();
    });
  }

  Future<void> _loadReminder() async {
    try {
      final item = await _service.getReminderById(widget.reminderId);
      if (mounted) setState(() => _item = item);
    } catch (e) {
      // Keep ringing with generic copy if the details can't be fetched.
      debugPrint('[ReminderAlarm] load failed: $e');
    }
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    setState(() => _dismissing = true);
    _vibrate?.cancel();
    _clock?.cancel();
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _notifications.cancel(widget.notificationId);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _vibrate?.cancel();
    _clock?.cancel();
    _player.dispose();
    super.dispose();
  }

  /// (title, body, icon, acknowledge label) derived from the loaded reminder.
  /// Mirrors the wording used for the notification itself.
  (String, String, IconData, String) _display() {
    final item = _item;
    if (item == null) {
      return ('Reminder', 'It\'s time for your reminder', Icons.alarm, 'Done');
    }
    if (item.type.toLowerCase() == 'appointment') {
      final doctor = (item.doctorName ?? '').trim();
      final location = (item.location ?? '').trim();
      final title =
          doctor.isNotEmpty ? 'Appointment: $doctor' : 'Appointment reminder';
      final body = location.isNotEmpty
          ? 'You have an appointment at $location'
          : 'You have an upcoming appointment';
      return (title, body, Icons.event_available, 'Got it');
    }
    final med = (item.medicineName ?? '').trim();
    final dose = (item.dosage ?? '').trim();
    final title = med.isNotEmpty ? med : 'Medication reminder';
    final body =
        dose.isNotEmpty ? 'Time to take $dose' : 'Time to take your medicine';
    return (title, body, Icons.medication_outlined, 'I took it');
  }

  @override
  Widget build(BuildContext context) {
    final (title, body, icon, ackLabel) = _display();
    final nowText = DateFormat('h:mm a').format(DateTime.now());
    final scheduled =
        _item != null ? ReminderFilters.displayDateTime(_item!) : null;

    // Block the hardware back button: the alarm can only be silenced by the
    // acknowledge button, so it can't be dismissed-and-forgotten.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.secondaryColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXL,
              vertical: AppTheme.spacingXXL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Text(
                  nowText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXXL),
                Center(
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 64, color: AppTheme.neutralWhite),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXL),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.neutralWhite,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.neutralWhite.withValues(alpha: 0.85),
                    fontSize: 18,
                    height: 1.4,
                  ),
                ),
                if (scheduled != null) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Scheduled for ${ReminderFormatters.time12(scheduled)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.neutralWhite.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _dismissing ? null : _dismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neutralWhite,
                      foregroundColor: AppTheme.secondaryColor,
                      disabledBackgroundColor:
                          AppTheme.neutralWhite.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      ),
                    ),
                    child: _dismissing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.secondaryColor,
                            ),
                          )
                        : Text(
                            ackLabel,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
