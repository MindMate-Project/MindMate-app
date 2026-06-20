import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/onboarding/presentation/screens/onboarding/common/onboarding_data.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        minimum: EdgeInsets.fromLTRB(38, 40, 38, 40),
        child: Column(
          children: [
            SizedBox(height: 40),
            Align(
              alignment: Alignment.topLeft,
              child: Image.asset(
                'assets/images/splash.png',
                width: 35,
                height: 31,
              ),
            ),

            const SizedBox(height: 60),

            Text(
              'Welcome',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 32,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 25),

            const Text(
              'How would you like to continue?',
              style: TextStyle(
                color: Color(0xFF525252),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            const Text(
              'Select your role to get a personalised experience',
              style: TextStyle(
                color: Color(0xFF6F6F6F),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: 'IBM Plex Sans',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 37),

            ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.onboarding, extra: caregiverOnboardingData);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                fixedSize: const Size(269, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text(
                'Continue as Caregiver',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 23),

            ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.onboarding, extra: patientOnboardingData);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                fixedSize: const Size(269, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: const Text(
                'Continue as Patient',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
