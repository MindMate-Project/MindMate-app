import 'package:flutter/material.dart';
import 'package:mindmate/features/onboarding/presentation/screens/onboarding/common/onboarding_item.dart';
import 'package:mindmate/features/onboarding/presentation/screens/onboarding/common/onboarding_page.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Single onboarding flow for both patient and caregiver.
/// Pass [items] from [patientOnboardingData] or [caregiverOnboardingData].
class OnboardingScreen extends StatefulWidget {
  final List<OnboardingItem> items;

  const OnboardingScreen({super.key, required this.items});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < widget.items.length - 1) {
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

  void _goToAuth() {
    Navigator.pushReplacementNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == items.length - 1;

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 37, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/images/splash.png', width: 35, height: 31),
                TextButton(onPressed: _goToAuth, child: const Text('Skip')),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: items.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) =>
                    OnboardingPage(item: items[index]),
              ),
            ),
            SmoothPageIndicator(
              controller: _pageController,
              count: items.length,
              onDotClicked: (index) => _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              effect: const ExpandingDotsEffect(
                activeDotColor: AppTheme.primaryColor,
                dotColor: Color(0xFFE0E0E0),
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
              ),
            ),
            const SizedBox(height: 33),
            _buildBottomButtons(isFirst, isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(bool isFirst, bool isLast) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      fixedSize: const Size(219, 50),
    );

    if (isFirst) {
      return Center(
        child: ElevatedButton(
          onPressed: _nextPage,
          style: buttonStyle,
          child: const Text("Let's Start", style: AppTheme.elevatedButtonText),
        ),
      );
    }
    if (isLast) {
      return Center(
        child: ElevatedButton(
          onPressed: _goToAuth,
          style: buttonStyle,
          child: const Text('Register Now', style: AppTheme.elevatedButtonText),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: _previousPage,
          child: const Text(
            'Back',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
          ),

          child: IconButton(
            onPressed: _nextPage,
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.backgroundWhite,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
