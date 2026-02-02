
class MockAuthService {
  // Store verification codes with email
  static final Map<String, String> _verificationCodes = {};

  // Store user credentials for testing
  static final Map<String, String> _users = {
    'user@example.com': 'OldPassword123!',
    'test@gmail.com': 'TestPass456!',
    'omnia@email.com': 'OmniaPass789!',
  };

  // Generate a random 6-digit code
  static String _generateCode() {
    return (100000 + (DateTime.now().millisecond % 900000)).toString();
  }

  // Simulate sending verification code
  static Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    await Future.delayed(const Duration(seconds: 2));

    // Check if email exists in our mock users
    if (!_users.containsKey(email)) {
      return {
        'success': false,
        'message': 'Email not found in our system',
        'code': null,
      };
    }

    // Generate and store code
    final code = _generateCode();
    _verificationCodes[email] = code;

    // In real app, send email here
    print('Mock Email Sent to $email');
    print('Verification Code: $code'); // For testing purposes

    return {
      'success': true,
      'message': 'Verification code sent to $email',
      'code': code, // Remove this in production!
    };
  }

  // Verify the code entered by user
  static Future<Map<String, dynamic>> verifyCode(
    String email,
    String enteredCode,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    if (!_verificationCodes.containsKey(email)) {
      return {
        'success': false,
        'message': 'No code found for this email. Please send code again.',
      };
    }

    if (_verificationCodes[email] != enteredCode) {
      return {
        'success': false,
        'message': 'Invalid verification code. Please try again.',
      };
    }

    return {'success': true, 'message': 'Code verified successfully'};
  }

  // Reset password
  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String newPassword,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    if (!_users.containsKey(email)) {
      return {'success': false, 'message': 'Email not found'};
    }

    // Update password in mock database
    _users[email] = newPassword;

    // Clear verification code
    _verificationCodes.remove(email);

    return {'success': true, 'message': 'Password reset successfully'};
  }

  // Get mock users for reference (for testing)
  static List<String> getMockEmails() {
    return _users.keys.toList();
  }
}
