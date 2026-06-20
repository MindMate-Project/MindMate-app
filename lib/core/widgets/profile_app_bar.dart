import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// App bar used for profile section screens (Edit Profile, Notifications, etc.).
class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProfileAppBar({
    super.key,
    required this.title,
    this.centerTitle,
    this.showBackButton,
    this.actions,
  });

  final String title;
  final bool? centerTitle;
  final bool? showBackButton;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle ?? false,
      leading: showBackButton ?? true
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 30,
                color: AppTheme.neutralWhite,
              ),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          color: AppTheme.neutralWhite,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppTheme.neutralSkyBlue,
      actions: actions,
    );
  }
}
