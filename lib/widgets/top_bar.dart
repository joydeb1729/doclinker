import 'package:flutter/material.dart';
import '../app_theme.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool showNotificationBadge;
  final bool showProfileBadge;

  const TopBar({
    super.key,
    this.onNotificationTap,
    this.onProfileTap,
    this.showNotificationBadge = false,
    this.showProfileBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: AppTheme.cardShadow,
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 12 : 16,
          ),
          child: Row(
            children: [
              // Logo and App Name
              Expanded(
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: isSmallScreen ? 28 : 32,
                      height: isSmallScreen ? 28 : 32,
                      decoration: AppTheme.gradientDecoration,
                      child: Icon(
                        Icons.medical_services,
                        color: Colors.white,
                        size: isSmallScreen ? 16 : 18,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    // App Title
                    Text(
                      'DocLinker',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontSize: isSmallScreen ? 18 : 20,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Notification Bell
              GestureDetector(
                onTap: onNotificationTap,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.textSecondary,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      if (showNotificationBadge)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: isSmallScreen ? 6 : 8,
                            height: isSmallScreen ? 6 : 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(width: isSmallScreen ? 8 : 12),
              
              // Profile Icon
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: AppTheme.textSecondary,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      if (showProfileBadge)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: isSmallScreen ? 6 : 8,
                            height: isSmallScreen ? 6 : 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
} 