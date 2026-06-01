import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/patient/reminders/data/models/notify_before_options.dart';

/// Optional 24h / 1h lead-time alerts
class NotifyBeforeField extends StatelessWidget {
  const NotifyBeforeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final NotifyBeforeOptions value;
  final ValueChanged<NotifyBeforeOptions> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Remind me (notifications)',
          style: AppTheme.label.copyWith(fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: AppTheme.spacingS),
        CheckboxListTile(
          value: value.remind24h,
          onChanged: enabled
              ? (v) => onChanged(
                  NotifyBeforeOptions(
                    remind24h: v ?? false,
                    remind1h: value.remind1h,
                  ),
                )
              : null,
          title: const Text('24 hours before'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppTheme.primaryColor,
        ),
        CheckboxListTile(
          value: value.remind1h,
          onChanged: enabled
              ? (v) => onChanged(
                  NotifyBeforeOptions(
                    remind24h: value.remind24h,
                    remind1h: v ?? false,
                  ),
                )
              : null,
          title: const Text('1 hour before'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }
}
