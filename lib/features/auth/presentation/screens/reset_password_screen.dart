import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/auth/data/services/auth_service.dart';
import 'package:mindmate/core/widgets/password_form_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? email;

  const ResetPasswordScreen({super.key, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      final email = widget.email?.trim();
      if (email == null || email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Session expired. Please start from Forgot Password again.',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final authService = AuthService();
        await authService.resetPassword(
          email,
          _passwordController.text,
          _confirmPasswordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Password reset successfully. Log in with your new password.',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 54),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 17),
                child: Image.asset(
                  'assets/images/splash.png',
                  width: 52,
                  height: 50,
                ),
              ),

              SizedBox(height: 32),

              Text("Set new password", style: AppTheme.heading2),

              SizedBox(height: 26),

              Text(
                "Ensure it differs from previous ones for security",
                style: AppTheme.caption,
              ),
              SizedBox(height: 35),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Password Field
                    Text("Set Password", style: AppTheme.label),
                    SizedBox(height: 8),
                    PasswordFormField(controller: _passwordController),
                    SizedBox(height: 22),

                    // Confirm Password Field
                    Text("Confirm Password", style: AppTheme.label),
                    SizedBox(height: 8),
                    PasswordFormField(
                      controller: _confirmPasswordController,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      hintText: 'Re-enter your password',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 37),

              // Reset Password Button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    // disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Update Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
