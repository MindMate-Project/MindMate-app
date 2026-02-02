import 'package:flutter/material.dart';
import 'package:mindmate/themes/app_theme.dart';
import '../common/onboarding_item.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(item.imagePath, height: 200),
            const SizedBox(height: 16),
            Text(
              item.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppTheme.textButton,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF525252),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6F6F6F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
