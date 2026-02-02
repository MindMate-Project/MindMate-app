import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF14274E);
  static const Color secondaryColor = Color(0xFF5EA5C0);

  // Background Colors
  // static const Color backgroundColor = Color(0xFFF1F6F9);
  static const Color backgroundWhite = Colors.white;
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF14274E);
  static const Color textSecondary = Color(0xFF6C7278); //grey
  static const Color textTertiary = Color(0xFFA9A9A9); //placeholders
  static const Color textWhite = Colors.white;
  static const Color textButton = Color(0xFF5EA5C0);

  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Typography
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: primaryColor,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: primaryColor,
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
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: -0.17,
    height: 1.0,
  );

  static const TextStyle hintText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    letterSpacing: 0,
  );

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 10.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;

  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundWhite,
      cardColor: cardColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Inter',

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 118, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),

      // Text Button Theme
      // textButtonTheme: TextButtonThemeData(
      //   style: TextButton.styleFrom(
      //     foregroundColor: textButton,
      //     padding: const EdgeInsets.symmetric(
      //       horizontal: spacingL,
      //       vertical: spacingS,
      //     ),
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(radiusMedium),
      //     ),
      //   ),
      // ),

      // Input Decoration Theme
      // inputDecorationTheme: InputDecorationTheme(
      //   filled: true,
      //   fillColor: grey50,
      //   border: OutlineInputBorder(
      //     borderRadius: BorderRadius.circular(radiusMedium),
      //     borderSide: const BorderSide(color: grey200),
      //   ),
      //   enabledBorder: OutlineInputBorder(
      //     borderRadius: BorderRadius.circular(radiusMedium),
      //     borderSide: const BorderSide(color: grey200),
      //   ),
      //   focusedBorder: OutlineInputBorder(
      //     borderRadius: BorderRadius.circular(radiusMedium),
      //     borderSide: const BorderSide(color: primaryColor, width: 2),
      //   ),
      //   errorBorder: OutlineInputBorder(
      //     borderRadius: BorderRadius.circular(radiusMedium),
      //     borderSide: const BorderSide(color: errorColor),
      //   ),
      //   contentPadding: const EdgeInsets.symmetric(
      //     horizontal: spacingL,
      //     vertical: spacingM,
      //   ),
      // ),
    );
  }
}
