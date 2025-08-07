import 'package:flutter/material.dart';
import '../app_theme.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 16,
            vertical: isSmallScreen ? 6 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Assistant',
                isSmallScreen: isSmallScreen,
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Appointments',
                isSmallScreen: isSmallScreen,
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                label: 'History',
                isSmallScreen: isSmallScreen,
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: Icons.location_on_outlined,
                activeIcon: Icons.location_on,
                label: 'Nearby',
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSmallScreen,
  }) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8 : 12,
          vertical: isSmallScreen ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isActive 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive 
                  ? AppTheme.primaryColor
                  : AppTheme.textLight,
              size: isSmallScreen ? 20 : 22,
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive 
                    ? AppTheme.primaryColor
                    : AppTheme.textLight,
                fontWeight: isActive 
                    ? FontWeight.w600
                    : FontWeight.normal,
                fontSize: isSmallScreen ? 10 : 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
} 