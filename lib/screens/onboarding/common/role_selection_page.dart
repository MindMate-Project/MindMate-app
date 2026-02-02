import 'package:flutter/material.dart';
import 'package:mindmate/themes/app_theme.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              Image.asset('assets/images/splash.png', width: 35, height: 31),

              const SizedBox(height: 73),

              Text(
                'Welcome',
                style: TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

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
                  Navigator.of(context).pushNamed('/caregiver_onboarding');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  fixedSize: const Size(269, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  'Continue as Caregiver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 23),

              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/patient_onboarding');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  fixedSize: const Size(269, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  'Continue as Patient',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
