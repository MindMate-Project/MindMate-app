import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';

class ProfileMenuOption {
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  const ProfileMenuOption({
    required this.title,
    required this.onTap,
    this.trailing,
  });
}

class ProfileMenuList extends StatelessWidget {
  const ProfileMenuList({super.key, required this.options});
  final List<ProfileMenuOption> options;

  @override
  Widget build(BuildContext context) {
    return Container(
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
}
