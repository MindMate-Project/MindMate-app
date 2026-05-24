import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF5EA5C0);
  static const Color secondaryColor = Color(0xFF14274E);
  static const Color accentColor = Color(0xff525252);

  //Neutral Colors
  static const Color neutralLight = Color(0xFFF1F6F9);
  static const Color neutralDark = Color(0xFF6C7278);
  static const Color neutralMedium = Color(0xFF9BA4B4);
  static const Color neutralLightBlue = Color(0xFFB9C0C9);
  static const Color neutralSkyBlue = Color(0xFF8EC0D3);
  static const Color neutralWhite = Colors.white;
  static const Color neutralBlack = Colors.black;

  // Background Colors
  static const Color backgroundWhite = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF5EA5C0);
  static const Color textSecondary = Color(0xFF6C7278); //grey
  static const Color textTertiary = Color(0xFF9BA4B4); //placeholders
  static const Color textWhite = Colors.white;
  static const Color textButton = Color(0xFF5EA5C0);

  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Typography

  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: primaryColor,
    letterSpacing: -0.017,
    height: 1.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: primaryColor,
    height: 1.2,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textTertiary,
    height: 1.3,
  );

  static const TextStyle bodyXSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: -0.01,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: neutralDark,
    letterSpacing: -0.17,
    height: 1.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: secondaryColor,
    height: 1.2,
  );

  static const TextStyle hintText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: neutralMedium,
    height: 1.2,
  );
  static const TextStyle elevatedButtonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.2,
    color: neutralWhite,
  );

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 10.0;
  static const double radiusXL = 50.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;

  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 30.0;
  static const double spacingXXXXL = 32.0;
}
