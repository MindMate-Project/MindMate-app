import 'package:email_validator/email_validator.dart';

class ValidationUtils {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    if (!EmailValidator.validate(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[+!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (name.contains(RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]'))) {
      return 'Name cannot contain numbers or special characters';
    }
    return null;
  }

  // static String? validatePhone(String? phone) {
  //   if (phone == null || phone.isEmpty) {
  //     return null; // Phone is optional
  //   }
  //   if (!RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$').hasMatch(phone)) {
  //     return 'Enter a valid phone number';
  //   }
  //   return null;
  // }

  static String? validateAge(DateTime? birthDate) {
    if (birthDate == null) return null;

    final now = DateTime.now();
    int age = now.year - birthDate.year;

    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age < 13 ? 'You must be at least 13 years old' : null;
  }
}
