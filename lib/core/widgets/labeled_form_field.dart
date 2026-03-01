import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// Wraps a form field with a label above it.
class LabeledFormField extends StatelessWidget {
  const LabeledFormField({
    super.key,
    required this.label,
    required this.child,
    this.labelStyle,
  });

  final String label;
  final Widget child;
  final TextStyle? labelStyle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: AppTheme.spacingS),
        child,
      ],
    );
  }
}
