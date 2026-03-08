import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/utils/validation.utils.dart';
import 'package:mindmate/core/widgets/password_form_field.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        minimum: EdgeInsets.fromLTRB(24, 26, 24, 39),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
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
                SizedBox(height: 30),
                // Title
                Column(
                  spacing: AppTheme.spacingS,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Login to your Account", style: AppTheme.heading1),
                    Text(
                      "Enter your email and password to log in",
                      style: AppTheme.caption,
                    ),
                  ],
                ),

                SizedBox(height: AppTheme.spacingXXL),

                // Email field
                Column(
                  spacing: AppTheme.spacingS,
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

                SizedBox(height: AppTheme.spacingL),

                // Password field
                Column(
                  spacing: AppTheme.spacingS,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Password", style: AppTheme.label),
                    PasswordFormField(controller: _passwordController),
                  ],
                ),

                SizedBox(height: AppTheme.spacingL),

                // Forgot password
                Align(
                  // heightFactor: 0.5,
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/forgot_password');
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all<EdgeInsets>(
                        EdgeInsets.zero,
                      ),
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppTheme.spacingL),

                // Login button
                BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthSuccess) {
                      final route = state.user.role == 'caregiver'
                          ? '/caregiver_home'
                          : '/patient_home';
                      Navigator.of(context).pushReplacementNamed(route);
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
                        onPressed: state is AuthLoading ? null : _handleLogin,
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
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                      ),
                    );
                  },
                ),

                SizedBox(height: AppTheme.spacingL),

                Column(
                  children: <Widget>[
                    Row(
                      spacing: AppTheme.spacingL,
                      children: <Widget>[
                        Expanded(
                          child: Divider(color: Color(0xFFEDF1F3), height: 18),
                        ),
                        Text("OR", style: AppTheme.bodyXSmall),
                        Expanded(
                          child: Divider(color: Color(0xFFEDF1F3), height: 18),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: AppTheme.spacingM),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      // log in with google
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.backgroundWhite,
                      foregroundColor: Color(0xFF1A1C1E),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Color(0xffEFF0F6)),
                      ),
                      elevation: 0,
                    ),
                    child: Wrap(
                      spacing: 10,
                      children: [
                        Image.asset(
                          'assets/images/google_icon.png',
                          width: 18,
                          height: 18,
                        ),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 107),
                // Sign up link
                Center(
                  child: Wrap(
                    spacing: 0,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: AppTheme.caption),

                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/signup');
                        },
                        child: Text(
                          'Sign Up',
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
