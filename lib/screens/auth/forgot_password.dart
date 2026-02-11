import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/themes/app_theme.dart';
import 'package:mindmate/services/mock_auth_service.dart';
import 'package:mindmate/widgets/custom_text_form_field.dart';
import '../../utils/validation.utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _statusMessage = null;
      });

      try {
        final result = await MockAuthService.sendVerificationCode(
          _emailController.text.trim(),
        );

        if (mounted) {
          if (result['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: AppTheme.successColor,
              ),
            );
            // Navigate to verify code screen with email
            Navigator.of(context).pushNamed(
              '/verify-code',
              arguments: _emailController.text.trim(),
            );
          } else {
            setState(() => _statusMessage = result['message']);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          setState(() => _isLoading = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'An error occurred. Please try again.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 36, left: 0),
                child: Image.asset(
                  '../assets/images/splash.png',
                  width: 50,
                  height: 50,
                ),
              ),

              Text("Forgot Password?", style: AppTheme.heading1),

              SizedBox(height: 17),

              Text(
                "Don't worry! Enter your email to reset the password",
                style: AppTheme.caption,
              ),
              SizedBox(height: 35),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Email", style: AppTheme.label),

                    SizedBox(height: 8),
                    CustomTextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Enter your email',
                      validator: (value) =>
                          ValidationUtils.validateEmail(value),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,

                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade400,
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
                          'Send Code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20),
              // Back to login link
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      color: AppTheme.secondaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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
