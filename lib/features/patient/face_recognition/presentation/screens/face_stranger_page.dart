import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'face_camera_page.dart';

class FaceStrangerPage extends StatelessWidget {
  final String? capturedImagePath;

  const FaceStrangerPage({Key? key, this.capturedImagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/patient_home')),
        ),
        title: const Text(
          'Face Recognition',
          style: TextStyle(color: Colors.white),
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
                'Person Not Found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Display the captured image with not-found badge
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red, width: 3),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: capturedImagePath != null
                          ? Image.file(
                              File(capturedImagePath!),
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person, size: 100, color: Colors.grey);
                              },
                            )
                          : const Icon(Icons.person, size: 100, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This person is NOT in the database',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This person was not found in the system. Please verify their identity or add them to the database.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Go back to camera page to take another photo
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FaceCameraPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add new patient feature coming soon...'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add Patient',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
