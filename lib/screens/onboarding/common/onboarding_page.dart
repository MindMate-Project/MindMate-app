import 'package:flutter/material.dart';
import 'package:mindmate/themes/app_theme.dart';
import '../common/onboarding_item.dart';

class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        
        Expanded(
          flex: 3,
          child: Center(
            child: Image.asset(
              item.imagePath,
              fit: BoxFit.contain,
              height: 200, 
            ),
          ),
        ),

        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textButton,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (item.subtitle.isNotEmpty)
                    Text(
                      item.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff525252),
                      ),
                    ),
                  if (item.subtitle.isNotEmpty) const SizedBox(height: 16),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xff6F6F6F),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
