import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/patient/face_recognition/data/services/face_recognition_service.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'face_identified_page.dart';
import 'face_stranger_page.dart';

class FaceScanningPage extends StatefulWidget {
  final String? imagePath;

  const FaceScanningPage({super.key, this.imagePath});

  @override
  State<FaceScanningPage> createState() => _FaceScanningPageState();
}

class _FaceScanningPageState extends State<FaceScanningPage> {
  String _statusMessage = 'Analyzing face...';
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    if (widget.imagePath == null) {
      _showError('No image provided');
      return;
    }

    setState(() {
      _statusMessage = 'Uploading image...';
    });

    debugPrint('🔍 Starting face recognition...');

    // Get token from AuthCubit
    String? token;
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      token = authState.token;
    }

    final result = await FaceRecognitionService.identifyFace(
      widget.imagePath!,
      token: token,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];
      debugPrint('📊 API Response: $data');

      bool isRecognized = false;
      Map<String, dynamic>? personData;

      if (data['identified'] == true || data['recognized'] == true) {
        isRecognized = true;

        if (data['person'] != null) {
          personData = data['person'];
        } else if (data['patient'] != null) {
          personData = data['patient'];
        } else if (data['user'] != null) {
          personData = data['user'];
        } else if (data['data'] != null) {
          personData = data['data'];
        } else {
          personData = data;
        }
      }

      if (isRecognized && personData != null) {
        final pd = personData;
        // Prepare the name by combining firstName and lastName from the JSON
        String firstName =
            pd['firstName'] ?? pd['name'] ?? 'Unknown';
        String lastName = pd['lastName'] ?? '';
        String fullName = lastName.isNotEmpty
            ? '$firstName $lastName'
            : firstName;

        // Use relationship for the "Nickname/Relation" field
        String relation =
            pd['relationship'] ?? pd['relation'] ?? 'Patient';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FaceIdentifiedPage(
              name: fullName,
              nickname: relation,
              confidence:
                  (pd['confidence'] ??
                          pd['similarity'] ??
                          pd['score'] ??
                          0.0)
                      .toDouble(),
              imageUrl:
                  pd['image_url'] ??
                  pd['photo'] ??
                  pd['avatar'],
              patientId: pd['id'] ?? pd['patient_id'],
              capturedImagePath: widget.imagePath,
            ),
          ),
        );
      } else {
        debugPrint('❌ Person not found');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                FaceStrangerPage(capturedImagePath: widget.imagePath),
          ),
        );
      }
    } else {
      debugPrint('❌ API Error: ${result['error']}');
      _showError(result['error'] ?? 'Unknown error occurred');
    }
  }

  void _showError(String error) {
    setState(() {
      _isProcessing = false;
      _statusMessage = 'Error occurred';
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Error'),
            ],
          ),
          content: Text(error, style: const TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isProcessing = true;
                  _statusMessage = 'Retrying...';
                });
                _processImage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Face Recognition',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryColor, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Stack(
                      children: [
                        widget.imagePath != null
                            ? Image.file(
                                File(widget.imagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  size: 100,
                                  color: Colors.grey,
                                ),
                              ),
                        if (_isProcessing) const _ScanningLineAnimation(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                if (_isProcessing) ...[
                  const Text(
                    'Processing...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Please wait...',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanningLineAnimation extends StatefulWidget {
  const _ScanningLineAnimation();

  @override
  State<_ScanningLineAnimation> createState() => _ScanningLineAnimationState();
}

class _ScanningLineAnimationState extends State<_ScanningLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanningLinePainter(_animation.value),
          child: Container(),
        );
      },
    );
  }
}

class _ScanningLinePainter extends CustomPainter {
  final double progress;
  _ScanningLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
