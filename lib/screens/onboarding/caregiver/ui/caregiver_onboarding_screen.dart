import 'package:flutter/material.dart';
import '../data/caregiver_onboarding_data.dart';
import 'package:mindmate/screens/onboarding/common/onboarding_page.dart';

class CaregiverOnboardingScreen extends StatefulWidget {
  const CaregiverOnboardingScreen({super.key});

  @override
  State<CaregiverOnboardingScreen> createState() =>
      _CaregiverOnboardingScreenState();
}

class _CaregiverOnboardingScreenState extends State<CaregiverOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  void _nextPage() {
    if (_currentIndex < caregiverOnboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToAuth();
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _goToAuth();
  }

  void _goToAuth() {
    Navigator.pushReplacementNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentIndex == caregiverOnboardingData.length - 1;

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 37, vertical: 40),
        child: Center(
          child: Column(
            children: [
              // Skip button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/splash.png',
                    width: 35,
                    height: 31,
                  ),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text('Skip'),
                  ),
                ],
              ),
              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: caregiverOnboardingData.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return OnboardingPage(item: caregiverOnboardingData[index]);
                  },
                ),
              ),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentIndex > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: Color(0xff5EA5C0),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),

                  IconButton(
                    onPressed: _nextPage,
                    icon: Icon(
                      // isLastPage
                      Icons.arrow_forward_ios_rounded,
                      color: const Color(0xff5EA5C0),
                      size: 30,
                    ),
                  ),
                  // ElevatedButton(
                  //   onPressed: _nextPage,
                  //   child: Text(isLastPage ? 'Get Started' : 'Next'),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
