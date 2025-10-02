import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_profile_provider.dart';
import '../screens/login_screen.dart';
import '../screens/patient_profile_screen.dart';
import '../utils/safe_provider_access.dart';
import 'top_bar.dart';
import 'bottom_nav_bar.dart';

class MainLayout extends ConsumerStatefulWidget {
  final List<Widget> pages;

  const MainLayout({super.key, required this.pages});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout>
    with SafeNavigationMixin {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load patient profile when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientProfileProvider.notifier).loadPatientProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: TopBar(
        onNotificationTap: () {
          // Handle notification tap
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        onProfileTap: () {
          // Show profile menu
          _showProfileMenu();
        },
        showNotificationBadge: true, // You can make this dynamic
        showProfileBadge: false, // You can make this dynamic
      ),
      body: IndexedStack(index: _currentIndex, children: widget.pages),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final profileState = ref.watch(patientProfileProvider);
          final profile = profileState.profile;

          return Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Profile header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: profile?.profileImageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.network(
                                  profile!.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.person,
                                        color: AppTheme.primaryColor,
                                        size: 30,
                                      ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: AppTheme.primaryColor,
                                size: 30,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (profileState.isLoading)
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              Text(
                                profile?.fullName ?? 'Loading...',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              profile?.email ?? 'Loading...',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                            if (profile != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Profile ${profile.completionPercentage.toInt()}% complete',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu items
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToPatientProfile(profile);
                  },
                ),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Settings')));
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Help & Support')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Sign Out',
                  onTap: () {
                    Navigator.pop(context);
                    _showSignOutDialog();
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToPatientProfile(profile) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientProfileScreen(initialProfile: profile),
      ),
    );

    // If profile was updated, refresh the profile data
    if (result != null) {
      ref.read(patientProfileProvider.notifier).loadPatientProfile();
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textPrimary),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => _performSignOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

  void _performSignOut() async {
    try {
      // Close the dialog first
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show loading indicator
      if (mounted) {
        safeShowDialog(
          (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Perform sign out - use safer ref access
      final auth = safeRead(authProvider);
      if (auth == null) {
        // Handle the case where auth provider couldn't be accessed
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
        safeShowSnackBar(
          SnackBar(
            content: const Text('Authentication error occurred'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
          ),
        );
        return;
      }

      final result = await auth.signOut();

      // Close loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      if (result.success) {
        // Clear patient profile data
        ref.read(patientProfileProvider.notifier).clearProfile();

        // Use safe navigation for better reliability
        safeNavigate(() {
          // Navigate to login screen and clear the navigation stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );

          // Show success message
          safeShowSnackBar(
            SnackBar(
              content: const Text('Successfully signed out'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
          );
        });
      } else {
        // Show error message
        safeShowSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Sign out failed'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading indicator if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      // Show error message with more context
      debugPrint('Sign out error: $e');
      safeShowSnackBar(
        SnackBar(
          content: Text('Sign out failed: Authentication error'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
        ),
      );
    }
  }
}
