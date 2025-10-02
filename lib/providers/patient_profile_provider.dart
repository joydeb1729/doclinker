import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_profile.dart';

// Patient profile state
class PatientProfileState {
  final PatientProfile? profile;
  final bool isLoading;
  final String? error;

  const PatientProfileState({this.profile, this.isLoading = false, this.error});

  PatientProfileState copyWith({
    PatientProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return PatientProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Patient profile notifier
class PatientProfileNotifier extends StateNotifier<PatientProfileState> {
  PatientProfileNotifier() : super(const PatientProfileState());

  /// Load patient profile for current user
  Future<void> loadPatientProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = state.copyWith(error: 'User not authenticated', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Try to get existing profile
      PatientProfile? profile = await PatientProfileService.getPatientProfile(
        user.uid,
      );

      // If no profile exists, create one from existing user data
      if (profile == null) {
        profile = await PatientProfileService.createPatientProfileFromUser(
          user.uid,
        );
      }

      state = state.copyWith(profile: profile, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load profile: $e',
        isLoading: false,
      );
    }
  }

  /// Update patient profile
  Future<void> updatePatientProfile(PatientProfile updatedProfile) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await PatientProfileService.updatePatientProfile(
        updatedProfile,
      );
      state = state.copyWith(profile: profile, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update profile: $e',
        isLoading: false,
      );
    }
  }

  /// Get or create patient profile
  Future<PatientProfile?> getOrCreatePatientProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      return await PatientProfileService.getOrCreatePatientProfile(user.uid);
    } catch (e) {
      print('Error getting or creating patient profile: $e');
      return null;
    }
  }

  /// Clear profile state (for logout)
  void clearProfile() {
    state = const PatientProfileState();
  }
}

// Provider for patient profile
final patientProfileProvider =
    StateNotifierProvider<PatientProfileNotifier, PatientProfileState>(
      (ref) => PatientProfileNotifier(),
    );

// Convenience provider for just the profile
final patientProfileDataProvider = Provider<PatientProfile?>((ref) {
  return ref.watch(patientProfileProvider).profile;
});

// Provider for profile loading state
final patientProfileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(patientProfileProvider).isLoading;
});

// Provider for profile error
final patientProfileErrorProvider = Provider<String?>((ref) {
  return ref.watch(patientProfileProvider).error;
});
