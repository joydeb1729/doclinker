import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/patient_profile_provider.dart';
import '../screens/login_screen.dart';
import '../screens/patient_profile_screen.dart';
import '../services/appointment_service.dart' as appointment_service;

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  int _totalAppointments = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadPatientStats();
    // Load patient profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientProfileProvider.notifier).loadPatientProfile();
    });
  }

  Future<void> _loadPatientStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final appointments = await appointment_service
            .AppointmentService.getPatientAppointments(user.uid);
        setState(() {
          _totalAppointments = appointments.length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    final profileState = ref.read(patientProfileProvider);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PatientProfileScreen(initialProfile: profileState.profile),
      ),
    );

    // If profile was updated, refresh the profile data and stats
    if (result != null) {
      ref.read(patientProfileProvider.notifier).loadPatientProfile();
      _loadPatientStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(patientProfileProvider);
    final profile = profileState.profile;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                // Avatar
                Container(
                  width: isSmallScreen ? 64 : 80,
                  height: isSmallScreen ? 64 : 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      isSmallScreen ? 32 : 40,
                    ),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: isSmallScreen ? 32 : 40,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                // User Info
                if (profileState.isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    profile?.fullName ?? 'Patient',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 18 : 20,
                    ),
                  ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  profile?.email ?? 'Loading...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 10 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Patient',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 10 : 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.calendar_today,
                  value: _isLoadingStats ? '...' : '$_totalAppointments',
                  label: 'Appointments',
                  color: AppTheme.primaryColor,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.account_circle,
                  value: profile != null
                      ? '${profile.completionPercentage.toInt()}%'
                      : '...',
                  label: 'Profile',
                  color: AppTheme.accentColor,
                  isSmallScreen: isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.verified_user,
                  value: profile?.isActive == true ? 'Active' : 'Inactive',
                  label: 'Status',
                  color: AppTheme.successColor,
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Menu Items
          _buildMenuSection(
            context,
            title: 'Account',
            items: [
              _buildMenuItem(
                context,
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                onTap: () => _navigateToEditProfile(),
                isSmallScreen: isSmallScreen,
              ),
              _buildMenuItem(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                onTap: () {},
                isSmallScreen: isSmallScreen,
              ),
              _buildMenuItem(
                context,
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Control your privacy settings',
                onTap: () {},
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          _buildMenuSection(
            context,
            title: 'Health',
            items: [
              _buildMenuItem(
                context,
                icon: Icons.medical_services_outlined,
                title: 'Medical Records',
                subtitle: 'View your health history',
                onTap: () {},
                isSmallScreen: isSmallScreen,
              ),
              _buildMenuItem(
                context,
                icon: Icons.medication_outlined,
                title: 'Medications',
                subtitle: 'Track your prescriptions',
                onTap: () {},
                isSmallScreen: isSmallScreen,
              ),
              _buildMenuItem(
                context,
                icon: Icons.favorite_outline,
                title: 'Health Goals',
                subtitle: 'Set and track wellness targets',
                onTap: () {},
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          _buildMenuSection(
            context,
            title: 'Support',
            items: [
              _buildMenuItem(
                context,
                icon: Icons.help_outline,
                title: 'Help Center',
                subtitle: 'Get help and find answers',
                onTap: () {},
                isSmallScreen: isSmallScreen,
              ),
              _buildMenuItem(
                context,
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                subtitle: 'Share your thoughts with us',
                onTap: () {},
                isSmallScreen: isSmallScreen,
              ),
              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () {},
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),

          SizedBox(height: isSmallScreen ? 16 : 24),

          // Logout Button
          GestureDetector(
            onTap: () => _showSignOutDialog(context, ref),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: AppTheme.errorColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout,
                    color: AppTheme.errorColor,
                    size: isSmallScreen ? 18 : 20,
                  ),
                  SizedBox(width: isSmallScreen ? 6 : 8),
                  Text(
                    'Sign Out',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isSmallScreen = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: isSmallScreen ? 18 : 20,
            ),
          ),
          SizedBox(height: isSmallScreen ? 1 : 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: isSmallScreen ? 10 : 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<Widget> items,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Container(
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      color: AppTheme.textLight.withOpacity(0.2),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isSmallScreen = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 32 : 40,
              height: isSmallScreen ? 32 : 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: isSmallScreen ? 16 : 20,
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 1 : 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textLight,
              size: isSmallScreen ? 18 : 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
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
              onPressed: () => _performSignOut(context, ref),
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

  void _performSignOut(BuildContext context, WidgetRef ref) async {
    try {
      // Close the dialog first
      Navigator.of(context).pop();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Perform sign out
      final auth = ref.read(authProvider);
      final result = await auth.signOut();

      // Close loading indicator
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (result.success) {
        // Navigate to login screen and clear the navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully signed out'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
          ),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
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
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign out failed: ${e.toString()}'),
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
