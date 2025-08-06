import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Custom result class for authentication operations
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  AuthResult({required this.success, this.errorMessage, this.user});

  factory AuthResult.success(User? user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult(success: false, errorMessage: errorMessage);
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Let it use the default client ID from google-services.json
  );

  // Test Google Sign-In configuration
  Future<bool> testGoogleSignInConfiguration() async {
    try {
      print('Testing Google Sign-In configuration...');
      
      // Try to get the current user without signing in
      final currentUser = await _googleSignIn.signInSilently();
      print('Current Google user: ${currentUser?.email ?? 'None'}');
      
      return true;
    } catch (e) {
      print('Google Sign-In configuration test failed: $e');
      return false;
    }
  }

  // Check if Google Play Services is available
  Future<bool> isGooglePlayServicesAvailable() async {
    try {
      // This will throw an exception if Google Play Services is not available
      await _googleSignIn.signInSilently();
      return true;
    } catch (e) {
      print('Google Play Services not available: $e');
      return false;
    }
  }

  // Check if Google Sign-In is available
  Future<bool> isGoogleSignInAvailable() async {
    try {
      final isAvailable = await _googleSignIn.isSignedIn();
      print('Google Sign-In availability check: $isAvailable');
      return true; // If we can check, the service is available
    } catch (e) {
      print('Google Sign-In not available: $e');
      return false;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Login with email and password
  Future<AuthResult> loginWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e.code);
      return AuthResult.failure(errorMessage);
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update user display name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName.trim());
      }

      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e.code);
      return AuthResult.failure(errorMessage);
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Login with Google
  Future<AuthResult> loginWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In was cancelled by user');
        return AuthResult.failure('Google sign-in was cancelled');
      }

      print('Google Sign-In successful for user: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('Google authentication tokens obtained');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Created Google Auth credential');

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);

      print('Firebase authentication successful for user: ${userCredential.user?.uid}');

      // Check if user is null
      if (userCredential.user == null) {
        print('Firebase authentication succeeded but user is null');
        return AuthResult.failure('Authentication succeeded but user data is missing. Please try again.');
      }

      return AuthResult.success(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      String errorMessage = _getErrorMessage(e.code);
      return AuthResult.failure(errorMessage);
    } catch (e) {
      print('Google Sign-In Exception: $e');
      
      // Handle specific Google Sign-In errors
      if (e.toString().contains('ApiException: 10')) {
        return AuthResult.failure(
          'Google Sign-In configuration error. Please check your Firebase console settings and ensure Google Sign-In is enabled.',
        );
      }
      
      // Handle type casting errors - if Firebase auth succeeded, treat as success
      if (e.toString().contains('PigeonUserDetails') || e.toString().contains('type cast')) {
        print('Type casting error detected, but Firebase authentication likely succeeded');
        // Check if we have a current user despite the error
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          print('Found current user despite type casting error: ${currentUser.uid}');
          return AuthResult.success(currentUser);
        }
        return AuthResult.failure(
          'Google Sign-In completed successfully, but there was an issue processing user details. Please try again.',
        );
      }
      
      return AuthResult.failure('Google sign-in failed. Please try again. Error: $e');
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success(null); // No user returned for password reset
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e.code);
      return AuthResult.failure(errorMessage);
    } catch (e) {
      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  // Logout
  Future<AuthResult> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure('Logout failed. Please try again.');
    }
  }

  // Update user profile
  Future<AuthResult> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (currentUser != null) {
        await currentUser!.updateDisplayName(displayName);
        if (photoURL != null) {
          await currentUser!.updatePhotoURL(photoURL);
        }
        return AuthResult.success(currentUser!);
      } else {
        return AuthResult.failure('No user is currently signed in');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e.code);
      return AuthResult.failure(errorMessage);
    } catch (e) {
      return AuthResult.failure('Profile update failed. Please try again.');
    }
  }

  // Get user profile
  User? getUserProfile() {
    return currentUser;
  }

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Send email verification
  Future<AuthResult> sendEmailVerification() async {
    try {
      if (currentUser != null && !currentUser!.emailVerified) {
        await currentUser!.sendEmailVerification();
        return AuthResult.success(currentUser!);
      } else {
        return AuthResult.failure('Email verification not needed');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getErrorMessage(e.code);
      return AuthResult.failure(errorMessage);
    } catch (e) {
      return AuthResult.failure('Email verification failed. Please try again.');
    }
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  // Mock login for development (when Firebase is not configured)
  Future<AuthResult> mockLogin() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure('Mock login failed');
    }
  }
}
