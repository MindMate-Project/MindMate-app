import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/features/auth/domain/models/user_model.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';
import 'package:mindmate/core/widgets/date_picker_field.dart';
import 'package:mindmate/core/widgets/labeled_form_field.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/core/utils/validation.utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _genderController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final user = _getLoggedInUser();
    final nameParts = _splitName(user?.name ?? '');
    _firstNameController = TextEditingController(text: nameParts.$1);
    _lastNameController = TextEditingController(text: nameParts.$2);
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _genderController = TextEditingController(text: 'Male');
    _selectedDate = null; // Not in User model; mock for now
  }

  User? _getLoggedInUser() {
    final state = context.read<AuthCubit>().state;
    return state is AuthSuccess ? state.user : null;
  }

  (String, String) _splitName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      Navigator.pop(context);
    }
  }
  void _openGenderPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Male', 'Female']
              .map(
                (g) => ListTile(
                  title: Text(g),
                  onTap: () {
                    setState(() => _genderController.text = g);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const ProfileAppBar(title: 'Edit Profile Information'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingXXL),
              _buildProfileAvatar(),
              const SizedBox(height: AppTheme.spacingXXL),
              Row(
                children: [
                  Expanded(
                    child: LabeledFormField(
                      label: 'First Name',
                      child: CustomTextFormField(
                        controller: _firstNameController,
                        hintText: 'First Name',
                        validator: ValidationUtils.validateName,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingL),
                  Expanded(
                    child: LabeledFormField(
                      label: 'Last Name',
                      child: CustomTextFormField(
                        controller: _lastNameController,
                        hintText: 'Last Name',
                        validator: ValidationUtils.validateName,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),
              LabeledFormField(
                label: 'Email',
                child: CustomTextFormField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: ValidationUtils.validateEmail,
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              LabeledFormField(
                label: 'Phone Number',
                child: CustomTextFormField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              LabeledFormField(
                label: 'Birth Date',
                child: DatePickerField(
                  selectedDate: _selectedDate,
                  onDateSelected: (d) => setState(() => _selectedDate = d),
                  hintText: 'Birth Date',
                  dateFormat: DateFormat('d/M/yyyy'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              LabeledFormField(
                label: 'Gender',
                child: InkWell(
                  onTap: _openGenderPicker,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.backgroundWhite,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide:
                            const BorderSide(color: AppTheme.neutralMedium),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMedium),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryColor, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _genderController.text,
                          style: AppTheme.bodyLarge,
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: AppTheme.neutralMedium),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXXL),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                  child: const Text('Submit', style: AppTheme.elevatedButtonText),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Center(
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _firstNameController,
        builder: (context, value, _) {
          final initial = value.text.trim().isNotEmpty
              ? value.text.trim()[0].toUpperCase()
              : '?';
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // TODO: pick image 
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.neutralWhite,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppTheme.neutralBlack,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
