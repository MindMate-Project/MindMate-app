import 'package:flutter/material.dart';
import 'package:mindmate/themes/app_theme.dart';
import '../../utils/validation.utils.dart';
import '../../widgets/password_form_field.dart';
import '../../widgets/custom_text_form_field.dart';

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
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 36, 0, 10),
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
                    Text("Log in to your Account", style: AppTheme.heading1),
                    Text(
                      "Enter your email and password to log in",
                      style: AppTheme.caption,
                    ),
                  ],
                ),

                SizedBox(height: 22),

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

                SizedBox(height: 26),

                // Password field
                Column(
                  spacing: 8.0,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Password", style: AppTheme.label),
                    PasswordFormField(controller: _passwordController),
                  ],
                ),

                SizedBox(height: 22),

                // Forgot password
                Align(
                  // heightFactor: 0.5,
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      //handle reset pass
                    },
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all<EdgeInsets>(
                        EdgeInsets.zero,
                      ),
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppTheme.textButton,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 45),

                Column(
                  children: <Widget>[
                    Row(
                      spacing: 16,
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

                SizedBox(height: 12),
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
                          '../assets/images/google_icon.png',
                          width: 18,
                          height: 18,
                        ),
                        Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
