import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Size size;
  final Color backgroundColor; 
   
  const CustomElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.size,
    required this.backgroundColor,

  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: AppTheme.neutralWhite,
        fixedSize: size,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
      child: Text(
        text,
        style: AppTheme.elevatedButtonText,
        textAlign: TextAlign.center,
    ));
  }
}
