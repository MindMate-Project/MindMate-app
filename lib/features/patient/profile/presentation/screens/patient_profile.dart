import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/auth/domain/models/user_model.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/bottom_nav_bar_widget.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';

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
          body: SafeArea(
            child: Column(
              children: [
                const ProfileAppBar(title: 'Profile', centerTitle: true, showBackButton: false),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProfileSection(user),
                        _buildMenuOptions(context, user),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBarWidget(
        selectedIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/patient_home');
              break;
            case 1:
              Navigator.pushNamed(context, '/memory');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/patient_reminders');
              break;
            case 4:
              break; // Already on profile
            default:
              break;
          }
        },
      ),
        );
      },
    );
  }


  Widget _buildProfileSection(User? user) {
    final name = user?.name ?? '—';
    final email = user?.email ?? '—';
    final phone = user?.phoneNumber ?? '';
    final initial = name.isNotEmpty && name != '—' ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 48,
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
                  onTap: () => Navigator.pushNamed(context, '/edit_profile'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      size: 20,
                      color: AppTheme.neutralBlack,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                email,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              if (phone.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Text(
                  phone,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions(BuildContext context, User? user) {
    final isPatient = user?.role == 'patient';
    final options = [
      _ProfileOption(
        title: 'Edit Profile Information',
        onTap: () => _navigateTo('/edit_profile'),
      ),
      if (isPatient)
        _ProfileOption(
          title: 'Caregiver requests',
          onTap: () => _navigateTo('/patient_assignment_inbox'),
        ),
      _ProfileOption(
        title: 'Notifications',
        onTap: () => _navigateTo('/notifications'),
      ),
      _ProfileOption(
        title: 'Medical Information',
        onTap: () => _navigateTo('/medical_information'),
      ),
      _ProfileOption(
        title: 'Privacy Policy',
        onTap: () => _navigateTo('/privacy_policy'),
      ),
      _ProfileOption(
        title: 'Log out',
        onTap: () => _handleLogout(context),
        trailing: const Icon(
          Icons.logout_rounded,
          size: 14,
          color: AppTheme.neutralDark,
        ),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: options.asMap().entries.map((entry) {
          final isLast = entry.key == options.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: entry.value.onTap,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.neutralDark,
                          ),
                        ),
                      ),
                      if (entry.value.trailing != null) entry.value.trailing!,
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _navigateTo(String route) {
    Navigator.pushNamed(context, route);
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
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption {
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  _ProfileOption({required this.title, required this.onTap, this.trailing});
}
