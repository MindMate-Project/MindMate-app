import 'package:flutter/material.dart';
import '../data/caregiver_onboarding_data.dart';
import 'package:mindmate/screens/onboarding/common/onboarding_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:mindmate/themes/app_theme.dart';

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
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 37, vertical: 40),
        child: Center(
          child: Column(
            children: [
              // Skip button
              SizedBox(height: 40),
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

              SmoothPageIndicator(
                controller: _pageController,
                count: caregiverOnboardingData.length,
                onDotClicked: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                effect: const ExpandingDotsEffect(
                  activeDotColor: Color(0xff5EA5C0),
                  dotColor: Color(0xFFE0E0E0),
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 8,
                ),
              ),

              SizedBox(height: 33),

              // Buttons
              switch (_currentIndex) {
                0 => Center(
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff5EA5C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      fixedSize: const Size(219, 50),
                    ),
                    child: const Text(
                      "Let's Start",
                      style: AppTheme.elevatedButtonText,
                    ),
                  ),
                ),
                int index
                    when index > 0 &&
                        index < caregiverOnboardingData.length - 1 =>
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      ),
                      IconButton(
                        onPressed: _nextPage,
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xff5EA5C0),
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                int index when index == caregiverOnboardingData.length - 1 =>
                  Center(
                    child: ElevatedButton(
                      onPressed: _goToAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff5EA5C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        fixedSize: const Size(219, 50),
                      ),
                      child: const Text(
                        'Register',
                        style: AppTheme.elevatedButtonText,
                      ),
                    ),
                  ),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
