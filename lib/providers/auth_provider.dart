import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// AuthService provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth state provider with fallback for development
final authStateProvider = StreamProvider<User?>((ref) {
  try {
    final authService = ref.watch(authServiceProvider);
    return authService.authStateChanges;
  } catch (e) {
    // Return empty stream if Firebase is not configured
    return Stream.value(null);
  }
});

// Auth provider for login/logout operations
final authProvider = Provider<AuthProvider>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthProvider(authService);
});

class AuthProvider {
  final AuthService _authService;

  AuthProvider(this._authService);

  // Get current user
  User? get currentUser => _authService.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _authService.isLoggedIn;

  // Sign out
  Future<AuthResult> signOut() async {
    return await _authService.logout();
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _authService.loginWithEmailAndPassword(email, password);
  }

  // Create user with email and password
  Future<AuthResult> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    return await _authService.signUpWithEmailAndPassword(email, password, displayName);
  }

  // Google Sign-in
  Future<AuthResult> signInWithGoogle() async {
    return await _authService.loginWithGoogle();
  }

  // Check if Google Sign-In is available
  Future<bool> isGoogleSignInAvailable() async {
    return await _authService.isGoogleSignInAvailable();
  }

  // Check if Google Play Services is available
  Future<bool> isGooglePlayServicesAvailable() async {
    return await _authService.isGooglePlayServicesAvailable();
  }

  // Test Google Sign-In configuration
  Future<bool> testGoogleSignInConfiguration() async {
    return await _authService.testGoogleSignInConfiguration();
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  // Update user profile
  Future<AuthResult> updateUserProfile({String? displayName, String? photoURL}) async {
    return await _authService.updateUserProfile(displayName: displayName, photoURL: photoURL);
  }

  // Get user profile
  User? getUserProfile() {
    return _authService.getUserProfile();
  }

  // Check if email is verified
  bool get isEmailVerified => _authService.isEmailVerified;

  // Send email verification
  Future<AuthResult> sendEmailVerification() async {
    return await _authService.sendEmailVerification();
  }

  // Mock login for development (when Firebase is not configured)
  Future<AuthResult> mockLogin() async {
    return await _authService.mockLogin();
  }
} 