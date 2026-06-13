import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';

/// Centered error message with a Retry button. Shared by screens that load
/// data over the network (assignment inbox, caregiver/patient home, etc.).
class ErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  /// When true the content is wrapped in [Center]; set false to embed inline
  /// inside an existing column without forcing it to fill the viewport.
  final bool expand;

  const ErrorRetryView({
    super.key,
    required this.message,
    required this.onRetry,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
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
    );

    return expand ? Center(child: content) : content;
  }
}
