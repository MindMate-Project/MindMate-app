import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/features/auth/domain/models/register_request.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/password_form_field.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';
import 'package:mindmate/core/widgets/date_picker_field.dart';
import 'package:mindmate/core/utils/validation.utils.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  static const _roles = ['patient', 'caregiver'];
  static const _genders = ['male', 'female'];

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedRole;
  String? _selectedGender;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final request = RegisterRequest(
      name:
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole!,
      gender: _selectedGender!,
      address: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      dateOfBirth: _selectedDate,
    );

    context.read<AuthCubit>().register(request);
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  String _labelFor(String value) =>
      value[0].toUpperCase() + value.substring(1);

  Widget _labeledField({
    required String label,
    required Widget field,
  }) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.label),
        field,
      ],
    );
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
                  padding: const EdgeInsets.only(top: 26),
                  child: Image.asset(
                    'assets/images/splash.png',
                    width: 52,
                    height: 50,
                  ),
                ),
                Column(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sign Up', style: AppTheme.heading1),
                    Text(
                      'Create an account to continue!',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
                Row(
                  spacing: 16,
                  children: [
                    Expanded(
                      child: _labeledField(
                        label: 'First Name',
                        field: CustomTextFormField(
                          controller: _firstNameController,
                          keyboardType: TextInputType.name,
                          hintText: 'Enter your first name',
                          validator: ValidationUtils.validateName,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _labeledField(
                        label: 'Last Name',
                        field: CustomTextFormField(
                          controller: _lastNameController,
                          keyboardType: TextInputType.name,
                          hintText: 'Enter your last name',
                          validator: ValidationUtils.validateName,
                        ),
                      ),
                    ),
                  ],
                ),
                _labeledField(
                  label: 'Email',
                  field: CustomTextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'Enter your email',
                    validator: ValidationUtils.validateEmail,
                  ),
                ),
                _labeledField(
                  label: 'Set Password',
                  field: PasswordFormField(controller: _passwordController),
                ),
                _labeledField(
                  label: 'Confirm Password',
                  field: PasswordFormField(
                    controller: _confirmPasswordController,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    hintText: 'Re-enter your password',
                  ),
                ),
                _labeledField(
                  label: 'Role',
                  field: DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    hint: const Text('Select your role'),
                    items: _roles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(_labelFor(role)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedRole = value),
                    validator: (value) =>
                        ValidationUtils.validateRequired(value, 'Role'),
                    decoration: _dropdownDecoration(),
                  ),
                ),
                _labeledField(
                  label: 'Gender',
                  field: DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    hint: const Text('Select your gender'),
                    items: _genders
                        .map(
                          (gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(_labelFor(gender)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedGender = value),
                    validator: (value) =>
                        ValidationUtils.validateRequired(value, 'Gender'),
                    decoration: _dropdownDecoration(),
                  ),
                ),
                _labeledField(
                  label: 'Phone',
                  field: CustomTextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    hintText: 'Enter your phone number',
                    validator: (value) =>
                        ValidationUtils.validatePhone(value, required: true),
                  ),
                ),
                _labeledField(
                  label: 'Address',
                  field: CustomTextFormField(
                    controller: _addressController,
                    keyboardType: TextInputType.streetAddress,
                    hintText: 'Enter your address',
                    validator: (value) =>
                        ValidationUtils.validateRequired(value, 'Address'),
                  ),
                ),
                _labeledField(
                  label: 'Birth Date (optional)',
                  field: DatePickerField(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) => setState(() => _selectedDate = date),
                  ),
                ),
                const SizedBox(height: 10),
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
                      context.go(AppRoutes.login);
                    } else if (state is AuthFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.error)),
                      );
                    } else if (state is AuthRegisteredEmailFailed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Account created, but we couldn\'t send a verification email. '
                            'Please contact support to activate your account.',
                          ),
                          duration: Duration(seconds: 6),
                        ),
                      );
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
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
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
                const SizedBox(height: 24),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTheme.caption,
                      ),
                      TextButton(
                        onPressed: () {
                          context.go(AppRoutes.login);
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
