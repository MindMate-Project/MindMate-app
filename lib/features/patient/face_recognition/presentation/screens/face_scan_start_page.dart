import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'face_camera_page.dart';

class FaceScanStartPage extends StatelessWidget {
  const FaceScanStartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.neutralSkyBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
                Icons.arrow_back_ios,
                size: 30,
                color: AppTheme.neutralWhite,
              ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Face Recognition',
          style: TextStyle(
          fontSize: 20,
          color: AppTheme.neutralWhite,
          fontWeight: FontWeight.w500,
        ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              const Text(
                'Feeling confused and need help recognizing someone? \nPoint your camera at the person you want to scan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3142),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primaryColor, width: 3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Image.asset(
                    'assets/images/face_scan_placeholder.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.face_retouching_natural,
                          size: 100,
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FaceCameraPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Start Scan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Please make sure the person\'s face is clearly visible.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
