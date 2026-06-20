import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/user_avatar.dart';
import 'package:mindmate/features/auth/domain/models/user_model.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.user, required this.onEditTap});

  final User? user;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? '—';
    final email = user?.email ?? '—';
    final phone = user?.phoneNumber ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              UserAvatar(
                photoUrl: user?.photoUrl,
                name: user?.name,
                radius: 60,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditTap,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "• Email: $email",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              if (phone.isNotEmpty) ...[
                Text(
                  "• Phone: $phone",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
