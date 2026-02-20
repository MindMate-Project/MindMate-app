import 'package:flutter/material.dart';
import 'package:mindmate/themes/app_theme.dart';

typedef OnNavTap = void Function(int index);

class BottomNavBarWidget extends StatelessWidget {
  final int selectedIndex;
  final OnNavTap? onTap;

  const BottomNavBarWidget({Key? key, this.selectedIndex = 0, this.onTap})
    : super(key: key);

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onTap?.call(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', 0),
              _buildNavItem(Icons.psychology_outlined, 'Memory', 1),
              const SizedBox(width: 60), // Space for FAB
              _buildNavItem(Icons.access_time_outlined, 'Reminder', 3),
              _buildNavItem(Icons.person_outline, 'Profile', 4),
            ],
          ),
          // Center camera button
          Positioned(
            top: 0,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
