import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender { male, female, other }

class PatientProfile {
  final String uid;
  final String email;
  final String fullName;
  final String? phone;
  final DateTime? dateOfBirth;
  final Gender? gender;
  final String? address;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  PatientProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // Calculate age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // Profile completion percentage
  double get completionPercentage {
    int totalFields = 6;
    int completedFields = 0;

    if (fullName.isNotEmpty) completedFields++;
    if (email.isNotEmpty) completedFields++;
    if (phone?.isNotEmpty == true) completedFields++;
    if (dateOfBirth != null) completedFields++;
    if (gender != null) completedFields++;
    if (address?.isNotEmpty == true) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  // Gender display name
  String get genderDisplayName {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case null:
        return 'Not specified';
    }
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'gender': gender?.name,
      'address': address,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  // Create from Firestore document
  factory PatientProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PatientProfile(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'],
      dateOfBirth: _safeParseTimestamp(data['dateOfBirth']),
      gender: data['gender'] != null
          ? Gender.values.firstWhere(
              (e) => e.name == data['gender'],
              orElse: () => Gender.other,
            )
          : null,
      address: data['address'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: _safeParseTimestamp(data['createdAt']) ?? DateTime.now(),
      updatedAt: _safeParseTimestamp(data['updatedAt']) ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Helper method to safely parse Firestore timestamps
  static DateTime? _safeParseTimestamp(dynamic value) {
    try {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      print('Warning: Unexpected timestamp type: ${value.runtimeType}');
      return null;
    } catch (e) {
      print(
        'Error parsing timestamp: $e, value: $value, type: ${value.runtimeType}',
      );
      return null;
    }
  }

  // Create copy with updated fields
  PatientProfile copyWith({
    String? fullName,
    String? phone,
    DateTime? dateOfBirth,
    Gender? gender,
    String? address,
    String? profileImageUrl,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return PatientProfile(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'PatientProfile(uid: $uid, fullName: $fullName, email: $email, completionPercentage: ${completionPercentage.toStringAsFixed(1)}%)';
  }
}

/// Service class for managing patient profiles
class PatientProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'patient_profiles';

  /// Create a new patient profile from existing user data
  static Future<PatientProfile> createPatientProfileFromUser(String uid) async {
    try {
      // Get existing user data from users collection
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('User data not found in users collection');
      }

      final userData = userDoc.data()!;

      // Create profile using existing user data
      final profile = PatientProfile(
        uid: userData['uid'] ?? uid,
        email: userData['email'] ?? '',
        fullName: userData['name'] ?? '',
        createdAt: userData['createdAt'] != null
            ? (userData['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(uid)
          .set(profile.toFirestore());

      print('✅ Patient profile created successfully from existing user data');
      return profile;
    } catch (e) {
      print('❌ Error creating patient profile from user data: $e');
      throw Exception('Failed to create patient profile: $e');
    }
  }

  /// Get patient profile by UID
  static Future<PatientProfile?> getPatientProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();

      if (doc.exists) {
        return PatientProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('❌ Error getting patient profile: $e');
      throw Exception('Failed to get patient profile: $e');
    }
  }

  /// Get or create patient profile
  static Future<PatientProfile> getOrCreatePatientProfile(String uid) async {
    try {
      // Try to get existing profile
      PatientProfile? existingProfile = await getPatientProfile(uid);

      if (existingProfile != null) {
        return existingProfile;
      }

      // Create new profile from existing user data if it doesn't exist
      return await createPatientProfileFromUser(uid);
    } catch (e) {
      print('❌ Error getting or creating patient profile: $e');
      throw Exception('Failed to get or create patient profile: $e');
    }
  }

  /// Update patient profile
  static Future<PatientProfile> updatePatientProfile(
    PatientProfile profile,
  ) async {
    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(_collection)
          .doc(profile.uid)
          .set(updatedProfile.toFirestore(), SetOptions(merge: true));

      print('✅ Patient profile updated successfully');
      return updatedProfile;
    } catch (e) {
      print('❌ Error updating patient profile: $e');
      throw Exception('Failed to update patient profile: $e');
    }
  }

  /// Delete patient profile
  static Future<void> deletePatientProfile(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).delete();
      print('✅ Patient profile deleted successfully');
    } catch (e) {
      print('❌ Error deleting patient profile: $e');
      throw Exception('Failed to delete patient profile: $e');
    }
  }
}
