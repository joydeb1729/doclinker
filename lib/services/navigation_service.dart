import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';

class NavigationService {
  static final AuthService _authService = AuthService();

  // Navigate based on user role after authentication
  static Future<void> navigateBasedOnRole(
    BuildContext context,
    String uid,
  ) async {
    try {
      print('NavigationService: Checking role for user $uid');
      final isDoctor = await _authService.isDoctorUser(uid);
      print('NavigationService: User $uid isDoctor = $isDoctor');

      if (context.mounted) {
        if (isDoctor) {
          print('NavigationService: Navigating to doctor dashboard');
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/doctor-dashboard', (route) => false);
        } else {
          print('NavigationService: Navigating to home screen');
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      }
    } catch (e) {
      print('Error navigating based on role: $e');
      // Default to user home screen if there's an error
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      }
    }
  }

  // Check if user has access to route
  static Future<bool> hasAccessToRoute(String route, String uid) async {
    try {
      final isDoctor = await _authService.isDoctorUser(uid);

      // Doctor-only routes
      final doctorRoutes = [
        '/doctor-dashboard',
        '/doctor-profile',
        '/doctor-appointments',
        '/doctor-schedule',
      ];

      // User-only routes (AI assistant, etc.)
      final userRoutes = ['/chat', '/ai-assistant'];

      // Check doctor routes
      if (doctorRoutes.contains(route)) {
        return isDoctor;
      }

      // Check user-only routes
      if (userRoutes.contains(route)) {
        return !isDoctor;
      }

      // Common routes accessible to both
      return true;
    } catch (e) {
      print('Error checking route access: $e');
      return false;
    }
  }

  // Navigate to appropriate dashboard
  static Future<void> navigateToDashboard(
    BuildContext context,
    String uid,
  ) async {
    try {
      final isDoctor = await _authService.isDoctorUser(uid);

      if (context.mounted) {
        if (isDoctor) {
          Navigator.of(context).pushReplacementNamed('/doctor-dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      print('Error navigating to dashboard: $e');
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  // Navigate to login screen
  static void navigateToLogin(BuildContext context) {
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  // Navigate with role check
  static Future<void> navigateWithRoleCheck(
    BuildContext context,
    String route,
    String uid,
  ) async {
    final hasAccess = await hasAccessToRoute(route, uid);

    if (context.mounted) {
      if (hasAccess) {
        Navigator.of(context).pushNamed(route);
      } else {
        // Show access denied or redirect to appropriate screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have access to this feature'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get appropriate home route for user role
  static Future<String> getHomeRoute(String uid) async {
    try {
      final isDoctor = await _authService.isDoctorUser(uid);
      return isDoctor ? '/doctor-dashboard' : '/home';
    } catch (e) {
      print('Error getting home route: $e');
      return '/home';
    }
  }
}

// Route Guard Widget
class RoleGuard extends StatelessWidget {
  final Widget child;
  final String requiredRole; // 'doctor', 'user', or 'any'
  final Widget? fallbackWidget;

  const RoleGuard({
    super.key,
    required this.child,
    required this.requiredRole,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return fallbackWidget ?? const LoginScreen();
    }

    return FutureBuilder<bool>(
      future: _checkAccess(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return child;
        }

        return fallbackWidget ??
            Scaffold(
              appBar: AppBar(title: const Text('Access Denied')),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'You do not have access to this feature',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
      },
    );
  }

  Future<bool> _checkAccess(String uid) async {
    final AuthService authService = AuthService();

    try {
      if (requiredRole == 'any') {
        return true;
      }

      final isDoctor = await authService.isDoctorUser(uid);

      if (requiredRole == 'doctor') {
        return isDoctor;
      } else if (requiredRole == 'user') {
        return !isDoctor;
      }

      return false;
    } catch (e) {
      print('Error checking access: $e');
      return false;
    }
  }
}
