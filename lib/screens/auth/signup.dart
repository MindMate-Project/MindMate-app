import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/cubits/auth_cubit.dart';
import 'package:mindmate/cubits/auth_state.dart';
import 'package:mindmate/models/user_model.dart';
import 'package:mindmate/themes/app_theme.dart';
import '../../widgets/password_form_field.dart';
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
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  String? _selectedRole;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _relationController.dispose();

    super.dispose();
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      final user = User(
        name: '${_firstNameController.text} ${_lastNameController.text}',
        email: _emailController.text,
        role: _selectedRole ?? 'patient',
        relation: _selectedRole == 'caregiver'
            ? _relationController.text
            : null,
        phone: _selectedRole == 'caregiver' ? _phoneController.text : null,
      );
      context.read<AuthCubit>().register(user, _passwordController.text);
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
                  padding: const EdgeInsets.only(top: 26, left: 0),
                  child: Image.asset(
                    'assets/images/splash.png',
                    width: 52,
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
                            hintText: 'Enter your first name',
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
                            hintText: 'Enter your last name',
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
                // Column(
                //   spacing: 8.0,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text("Birth Date", style: AppTheme.label),
                //     DatePickerField(
                //       selectedDate: _selectedDate,
                //       onDateSelected: (date) {
                //         setState(() {
                //           _selectedDate = date;
                //         });
                //       },
                //     ),
                //   ],
                // ),

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

                // Role selection
                Column(
                  spacing: 8.0,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Role", style: AppTheme.label),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      hint: Text('Select your role'),
                      items: ['patient', 'caregiver'].map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role[0].toUpperCase() + role.substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a role';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                // Conditional fields for caregiver
                if (_selectedRole == 'caregiver') ...[
                  // Phone field
                  Column(
                    spacing: 8.0,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Phone", style: AppTheme.label),
                      CustomTextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        hintText: 'Enter your phone number',
                        validator: (value) {
                          if (_selectedRole == 'caregiver' &&
                              (value == null || value.isEmpty)) {
                            return 'Phone number is required for caregivers';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),

                  // Relation field
                  Column(
                    spacing: 8.0,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Relation", style: AppTheme.label),
                      CustomTextFormField(
                        controller: _relationController,
                        keyboardType: TextInputType.text,
                        hintText: 'Enter your relation to the patient',
                        validator: (value) {
                          if (_selectedRole == 'caregiver' &&
                              (value == null || value.isEmpty)) {
                            return 'Relation is required for caregivers';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 10),

                // Signup button
                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please check your email to activate your account, then you can log in.',
                          ),
                        ),
                      );
                      Navigator.of(context).pushReplacementNamed('/login');
                    } else if (state is AuthFailure) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(state.error)));
                    }
                  },
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: state is AuthLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Sign up',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
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
