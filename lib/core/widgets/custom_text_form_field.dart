import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String hintText;
  final bool readOnly;
  final bool enabled;

  const CustomTextFormField({
    super.key,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.hintText = '',
    this.readOnly = false,
    this.enabled = true,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: AppTheme.hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.neutralMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
        ),
      ),
      validator: widget.validator,
    );
  }
}
