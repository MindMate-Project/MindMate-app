import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/features/auth/domain/models/user_model.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/patient/profile/presentation/cubit/profile_cubit.dart';
import 'package:mindmate/features/patient/profile/presentation/cubit/profile_state.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';
import 'package:mindmate/core/widgets/date_picker_field.dart';
import 'package:mindmate/core/widgets/labeled_form_field.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/core/widgets/user_avatar.dart';
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
  bool _didPrefill = false;

  @override
  void initState() {
    super.initState();
    final user = _getLoggedInUser();
    final nameParts = _splitName(user?.name ?? '');
    _firstNameController = TextEditingController(text: nameParts.$1);
    _lastNameController = TextEditingController(text: nameParts.$2);
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _genderController = TextEditingController(text: _normalizeGender(user?.gender) ?? 'Male');
    _selectedDate = user?.dateOfBirth;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess) return;
      context.read<ProfileCubit>().loadMyProfile(role: authState.user.role);
    });
  }

  User? _getLoggedInUser() {
    final state = context.read<AuthCubit>().state;
    return state is AuthSuccess ? state.user : null;
  }

  String? _normalizeGender(String? g) {
    if (g == null) return null;
    final s = g.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s.startsWith('m')) return 'Male';
    if (s.startsWith('f')) return 'Female';
    return g;
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
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess) return;

      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
              .trim();

      context.read<ProfileCubit>().updateMyProfile(
            role: authState.user.role,
            name: fullName,
            phone: _phoneController.text.trim(),
            gender: _genderController.text.trim(),
            dateOfBirth: _selectedDate,
          );
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
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded && !_didPrefill) {
          _didPrefill = true;
          final nameParts = _splitName(state.user.name);
          _firstNameController.text = nameParts.$1;
          _lastNameController.text = nameParts.$2;
          _emailController.text = state.user.email;
          _phoneController.text = state.user.phoneNumber.toString();
          _genderController.text = _normalizeGender(state.user.gender) ?? _genderController.text;
          _selectedDate = state.user.dateOfBirth;
          setState(() {});
        }

        if (state is ProfileUpdateSuccess) {
          context.read<AuthCubit>().updateUser(state.user);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.pop(context);
        }

        if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isBusy = state is ProfileLoading || state is ProfileUpdating;

        return Scaffold(
          backgroundColor: AppTheme.backgroundWhite,
          appBar: const ProfileAppBar(title: 'Edit Profile Information'),
          body: AbsorbPointer(
            absorbing: isBusy,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
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
                            enabled: false,
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
                            onDateSelected: (d) =>
                                setState(() => _selectedDate = d),
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
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium),
                                  borderSide: const BorderSide(
                                      color: AppTheme.neutralMedium),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium),
                                  borderSide: const BorderSide(
                                      color: AppTheme.primaryColor, width: 1),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium),
                              ),
                            ),
                            child: const Text('Submit',
                                style: AppTheme.elevatedButtonText),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXXL),
                      ],
                    ),
                  ),
                ),
                if (isBusy)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x33FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar() {
    return Center(
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _firstNameController,
        builder: (context, value, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                photoUrl: _getLoggedInUser()?.photoUrl,
                name: value.text,
                radius: 50,
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
