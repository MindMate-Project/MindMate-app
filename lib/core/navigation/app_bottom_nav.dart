import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/widgets/bottom_nav_bar_widget.dart';
import 'package:mindmate/core/widgets/caregiver_bottom_nav.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';

/// Bottom navigation that switches between patient and caregiver bars by role.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  static bool isCaregiver(AuthState state) =>
      state is AuthSuccess && state.user.role == 'caregiver';

  static void navigate(BuildContext context, int index, {required bool caregiver}) {
    if (caregiver) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/caregiver_home');
        case 1:
          Navigator.pushReplacementNamed(context, '/memory');
        case 3:
          Navigator.pushReplacementNamed(context, '/patient_reminders');
        case 4:
          Navigator.pushReplacementNamed(context, '/profile');
      }
      return;
    }
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/patient_home');
      case 1:
        Navigator.pushNamed(context, '/memory');
      case 3:
        Navigator.pushReplacementNamed(context, '/patient_reminders');
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final caregiver = isCaregiver(state);
        void onTap(int index) {
          if (index == selectedIndex) return;
          navigate(context, index, caregiver: caregiver);
        }

        if (caregiver) {
          return CaregiverBottomNav(
            selectedIndex: selectedIndex,
            onTap: onTap,
          );
        }
        return BottomNavBarWidget(
          selectedIndex: selectedIndex,
          onTap: onTap,
        );
      },
    );
  }
}
