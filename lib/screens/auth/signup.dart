import 'package:flutter/material.dart';
import 'package:mindmate/themes/app_theme.dart';
import '../../widgets/password_form_field.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../utils/validation.utils.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  DateTime? _selectedDate;

  // bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 36, left: 0),
                  child: Image.asset(
                    'assets/images/splash.png',
                    width: 50,
                    height: 50,
                  ),
                ),

                // Title
                Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Sign Up", style: AppTheme.heading1),
                    Text(
                      "Create an account to continue!",
                      style: AppTheme.caption,
                    ),
                  ],
                ),

                // First and Last Name fields
                Row(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        spacing: 8.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("First Name", style: AppTheme.label),
                          CustomTextFormField(
                            controller: _firstNameController,
                            keyboardType: TextInputType.name,
                            hintText: 'Enter your firstname',
                            validator: (value) =>
                                ValidationUtils.validateName(value),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Column(
                        spacing: 8.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Last Name", style: AppTheme.label),
                          CustomTextFormField(
                            controller: _lastNameController,
                            keyboardType: TextInputType.name,
                            hintText: 'Enter your lastname',
                            validator: (value) =>
                                ValidationUtils.validateName(value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Email field
                Column(
                  spacing: 8.0,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Email", style: AppTheme.label),
                    CustomTextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Enter your email',
                      validator: (value) =>
                          ValidationUtils.validateEmail(value),
                    ),
                  ],
                ),

                // Birth date field
                Column(
                  spacing: 8.0,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Birth Date", style: AppTheme.label),
                    DatePickerField(
                      selectedDate: _selectedDate,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                    ),
                  ],
                ),

                // Password field
                Column(
                  spacing: 8.0,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Set Password", style: AppTheme.label),
                    PasswordFormField(controller: _passwordController),
                  ],
                ),

                // Confirm password
                Column(
                  spacing: 8.0,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Confirm Password", style: AppTheme.label),
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

                SizedBox(height: 10),

                // Signup button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Sign up link
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: AppTheme.caption,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textButton,
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
      ),
    );
  }
}
