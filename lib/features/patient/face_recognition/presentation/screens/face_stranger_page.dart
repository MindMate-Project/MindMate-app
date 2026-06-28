import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/assignments/data/models/connected_caregiver.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'face_camera_page.dart';

class FaceStrangerPage extends StatefulWidget {
  final String? capturedImagePath;

  const FaceStrangerPage({super.key, this.capturedImagePath});

  @override
  State<FaceStrangerPage> createState() => _FaceStrangerPageState();
}

class _FaceStrangerPageState extends State<FaceStrangerPage> {
  final AssignmentService _assignmentService = AssignmentService();

  ConnectedCaregiver? _caregiver;
  bool _loadingCaregiver = true;
  bool _calling = false;

  @override
  void initState() {
    super.initState();
    _loadPrimaryCaregiver();
  }

  Future<void> _loadPrimaryCaregiver() async {
    try {
      final caregivers = await _assignmentService.fetchMyCaregivers();
      // Primary = the first connected caregiver that has a phone number,
      // falling back to the first caregiver overall.
      final primary = caregivers.firstWhere(
        (c) => c.hasPhone,
        orElse: () => caregivers.isNotEmpty
            ? caregivers.first
            : const ConnectedCaregiver(id: '', name: ''),
      );
      if (!mounted) return;
      setState(() {
        _caregiver = primary.id.isEmpty ? null : primary;
        _loadingCaregiver = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCaregiver = false);
    }
  }

  Future<void> _callCaregiver() async {
    final phone = _caregiver?.phoneNumber?.trim();
    if (phone == null || phone.isEmpty) return;
    setState(() => _calling = true);
    try {
      final ok = await launchUrl(
        Uri(scheme: 'tel', path: phone),
        mode: LaunchMode.externalApplication,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the phone dialer.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start the call.')),
        );
      }
    } finally {
      if (mounted) setState(() => _calling = false);
    }
  }

  bool get _canCall =>
      !_loadingCaregiver && !_calling && (_caregiver?.hasPhone ?? false);

  String get _callLabel {
    if (_loadingCaregiver) return 'Call caregiver';
    final c = _caregiver;
    if (c == null || !c.hasPhone) return 'No caregiver to call';
    return 'Call ${c.firstName}';
  }

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
          onPressed: () {
            context.go(AppRoutes.patientHome);
          },
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
                      child: widget.capturedImagePath != null
                          ? Image.file(
                              File(widget.capturedImagePath!),
                              fit: BoxFit.cover,
                              width: 200,
                              height: 200,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person,
                                    size: 100, color: Colors.grey);
                              },
                            )
                          : const Icon(Icons.person,
                              size: 100, color: Colors.grey),
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
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
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
                      "If you're not sure who this is, call your caregiver for "
                      'help — or try scanning again.',
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
                        side: const BorderSide(
                            color: AppTheme.primaryColor, width: 2),
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
                    // Call the patient's caregiver for help instead of the old
                    // (non-functional) "Add Patient" action.
                    child: ElevatedButton.icon(
                      onPressed: _canCall ? _callCaregiver : null,
                      icon: (_loadingCaregiver || _calling)
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.call,
                              color: Colors.white, size: 20),
                      label: Text(
                        _callLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        disabledBackgroundColor: AppTheme.neutralMedium,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
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
