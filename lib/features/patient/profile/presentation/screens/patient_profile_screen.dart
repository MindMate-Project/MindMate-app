import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/profile/presentation/widgets/profile_header.dart';
import 'package:mindmate/features/profile/presentation/widgets/profile_menu_list.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthSuccess ? state.user : null;
        return Scaffold(
          backgroundColor: AppTheme.backgroundWhite,
          appBar: const ProfileAppBar(title: 'Profile'),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ProfileHeader(
                          user: user,
                          onEditTap: () => context.push(AppRoutes.editProfile),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ProfileMenuList(
                            options: [
                              ProfileMenuOption(
                                title: 'Edit Profile Information',
                                onTap: () =>
                                    context.push(AppRoutes.editProfile),
                              ),
                              ProfileMenuOption(
                                title: 'Caregivers',
                                onTap: () =>
                                    context.push(AppRoutes.patientCaregivers),
                              ),
                              ProfileMenuOption(
                                title: 'Caregiver requests',
                                onTap: () => context.push(
                                  AppRoutes.patientAssignmentInbox,
                                ),
                              ),
                              ProfileMenuOption(
                                title: 'Notifications Settings',
                                onTap: () =>
                                    context.push(AppRoutes.notifications),
                              ),
                              ProfileMenuOption(
                                title: 'Privacy Policy',
                                onTap: () =>
                                    context.push(AppRoutes.privacyPolicy),
                              ),
                              ProfileMenuOption(
                                title: 'Log out',
                                onTap: () => _handleLogout(context),
                                trailing: const Icon(
                                  Icons.logout_rounded,
                                  size: 14,
                                  color: AppTheme.neutralDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
        );
      },
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthCubit>().logout();
              context.go(AppRoutes.login);
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
