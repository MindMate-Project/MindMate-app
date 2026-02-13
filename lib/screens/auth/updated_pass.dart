import 'package:flutter/material.dart';
import 'package:mindmate/themes/app_theme.dart';

class UpdatedPass extends StatefulWidget {
  const UpdatedPass({super.key});

  @override
  State<UpdatedPass> createState() => _UpdatedPassState();
}

class _UpdatedPassState extends State<UpdatedPass> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F6F9),
      body: SafeArea(
        minimum: EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/splash.png'),
              SizedBox(height: 15),
              Text(
                textAlign: TextAlign.center,
                'Your password has been updated successfully',
                style: TextStyle(
                  fontSize: 20,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  // letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 24),
              Text(
                textAlign: TextAlign.center,
                'You can now log in with your new password',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: Color(0xff989898),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 41),
              Center(
                child: SizedBox(
                  width: 342,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
