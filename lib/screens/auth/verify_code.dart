import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/themes/app_theme.dart';
import 'package:mindmate/services/mock_auth_service.dart';
import 'package:pinput/pinput.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _resendCountdown--;
        });
      }
      return _resendCountdown > 0;
    });
  }

  void _handleVerifyCode() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter the verification code'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code must be 6 digits'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await MockAuthService.verifyCode(
        widget.email,
        _codeController.text,
      );

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppTheme.successColor,
            ),
          );
          // Navigate to reset password screen
          Future.delayed(const Duration(milliseconds: 500), () {
            Navigator.of(context).pushNamed('/reset-password');
          });
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _handleResendCode() async {
    if (_resendCountdown == 0) {
      setState(() => _isLoading = true);

      try {
        final result = await MockAuthService.sendVerificationCode(widget.email);

        if (mounted) {
          setState(() => _isLoading = false);
          if (result['success']) {
            _startResendCountdown();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Code resent to ${widget.email}'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
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
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppTheme.primaryColor, width: 2),
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppTheme.secondaryColor),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Icon(
                  Icons.arrow_back,
                  color: AppTheme.textPrimary,
                  size: 24,
                ),
              ),
              SizedBox(height: 32),

              Text("Check your email", style: AppTheme.heading1),

              SizedBox(height: 17),

              Text(
                "We’ve sent a password reset code to your email",
                style: AppTheme.caption,
              ),
              SizedBox(height: 35),

              // PIN Input
              Pinput(
                controller: _codeController,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                keyboardType: TextInputType.number,
                enabled: !_isLoading,
                onCompleted: (_) {
                  // Auto submit when complete
                  _handleVerifyCode();
                },
              ),

              SizedBox(height: 35),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerifyCode,
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
                          'Verify Code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 24),

              // Resend Code Section
              Center(
                child: Column(
                  children: [
                    Text(
                      "Didn't get the code?",
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 8),
                    if (_resendCountdown > 0)
                      Text(
                        "Resend in ${_resendCountdown}s",
                        style: TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _isLoading ? null : _handleResendCode,
                        child: Text(
                          'Resend Code',
                          style: TextStyle(
                            color: AppTheme.secondaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
