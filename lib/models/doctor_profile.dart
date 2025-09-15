import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfile {
  final String uid;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? profileImageUrl;

  // Medical Information
  final String medicalLicense;
  final List<String> specializations;
  final String hospitalAffiliation;
  final int yearsOfExperience;
  final String medicalDegree;
  final List<String> certifications;

  // Availability
  final Map<String, List<String>> weeklyAvailability; // day: [time slots]
  final double consultationFee;
  final bool isAvailableForEmergency;

  // Contact & Location
  final String clinicAddress;
  final String? clinicPhone;
  final double? latitude;
  final double? longitude;

  // Profile Status
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Statistics
  final int totalPatients;
  final double averageRating;
  final int totalReviews;

  DoctorProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
    required this.medicalLicense,
    required this.specializations,
    required this.hospitalAffiliation,
    required this.yearsOfExperience,
    required this.medicalDegree,
    this.certifications = const [],
    this.weeklyAvailability = const {},
    this.consultationFee = 0.0,
    this.isAvailableForEmergency = false,
    required this.clinicAddress,
    this.clinicPhone,
    this.latitude,
    this.longitude,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.totalPatients = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'medicalLicense': medicalLicense,
      'specializations': specializations,
      'hospitalAffiliation': hospitalAffiliation,
      'yearsOfExperience': yearsOfExperience,
      'medicalDegree': medicalDegree,
      'certifications': certifications,
      'weeklyAvailability': weeklyAvailability,
      'consultationFee': consultationFee,
      'isAvailableForEmergency': isAvailableForEmergency,
      'clinicAddress': clinicAddress,
      'clinicPhone': clinicPhone,
      'latitude': latitude,
      'longitude': longitude,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'totalPatients': totalPatients,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
    };
  }

  // Create from Firestore document
  factory DoctorProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return DoctorProfile(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      medicalLicense: data['medicalLicense'] ?? '',
      specializations: List<String>.from(data['specializations'] ?? []),
      hospitalAffiliation: data['hospitalAffiliation'] ?? '',
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
      medicalDegree: data['medicalDegree'] ?? '',
      certifications: List<String>.from(data['certifications'] ?? []),
      weeklyAvailability: Map<String, List<String>>.from(
        (data['weeklyAvailability'] ?? {}).map(
          (key, value) => MapEntry(key, List<String>.from(value ?? [])),
        ),
      ),
      consultationFee: (data['consultationFee'] ?? 0.0).toDouble(),
      isAvailableForEmergency: data['isAvailableForEmergency'] ?? false,
      clinicAddress: data['clinicAddress'] ?? '',
      clinicPhone: data['clinicPhone'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalPatients: data['totalPatients'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
    );
  }

  // Create copy with updated fields
  DoctorProfile copyWith({
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
    String? medicalLicense,
    List<String>? specializations,
    String? hospitalAffiliation,
    int? yearsOfExperience,
    String? medicalDegree,
    List<String>? certifications,
    Map<String, List<String>>? weeklyAvailability,
    double? consultationFee,
    bool? isAvailableForEmergency,
    String? clinicAddress,
    String? clinicPhone,
    double? latitude,
    double? longitude,
    bool? isVerified,
    bool? isActive,
    DateTime? updatedAt,
    int? totalPatients,
    double? averageRating,
    int? totalReviews,
  }) {
    return DoctorProfile(
      uid: uid,
      email: email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      medicalLicense: medicalLicense ?? this.medicalLicense,
      specializations: specializations ?? this.specializations,
      hospitalAffiliation: hospitalAffiliation ?? this.hospitalAffiliation,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      medicalDegree: medicalDegree ?? this.medicalDegree,
      certifications: certifications ?? this.certifications,
      weeklyAvailability: weeklyAvailability ?? this.weeklyAvailability,
      consultationFee: consultationFee ?? this.consultationFee,
      isAvailableForEmergency:
          isAvailableForEmergency ?? this.isAvailableForEmergency,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      clinicPhone: clinicPhone ?? this.clinicPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      totalPatients: totalPatients ?? this.totalPatients,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }

  // Get formatted availability text
  String get availabilityText {
    if (weeklyAvailability.isEmpty) return 'Availability not set';

    List<String> days = [];
    weeklyAvailability.forEach((day, times) {
      if (times.isNotEmpty) {
        days.add('$day: ${times.join(', ')}');
      }
    });

    return days.join('\n');
  }

  // Get specializations as formatted string
  String get specializationsText {
    return specializations.join(', ');
  }

  // Check if doctor is currently available
  bool get isCurrentlyAvailable {
    if (!isActive) return false;

    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final todaySlots = weeklyAvailability[currentDay] ?? [];

    for (String slot in todaySlots) {
      final parts = slot.split(' - ');
      if (parts.length == 2) {
        final startTime = parts[0];
        final endTime = parts[1];

        if (currentTime.compareTo(startTime) >= 0 &&
            currentTime.compareTo(endTime) <= 0) {
          return true;
        }
      }
    }

    return false;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }
}

// Doctor Service for Firestore operations
class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'doctor_profiles';

  // Create doctor profile
  Future<void> createDoctorProfile(DoctorProfile doctorProfile) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(doctorProfile.uid)
          .set(doctorProfile.toFirestore());
    } catch (e) {
      throw Exception('Failed to create doctor profile: $e');
    }
  }

  // Get doctor profile by UID
  Future<DoctorProfile?> getDoctorProfile(String uid) async {
    try {
      final doc = await _firestore.collection(_collection).doc(uid).get();
      if (doc.exists) {
        return DoctorProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get doctor profile: $e');
    }
  }

  // Get or create doctor profile by UID
  Future<DoctorProfile> getOrCreateDoctorProfile(
    String uid,
    String email,
    String fullName,
  ) async {
    try {
      final existingProfile = await getDoctorProfile(uid);
      if (existingProfile != null) {
        return existingProfile;
      }

      // Create default doctor profile
      final defaultProfile = DoctorProfile(
        uid: uid,
        email: email,
        fullName: fullName,
        medicalLicense: '', // To be filled during profile setup
        specializations: [], // To be filled during profile setup
        hospitalAffiliation: '', // To be filled during profile setup
        yearsOfExperience: 0,
        medicalDegree: '', // To be filled during profile setup
        clinicAddress: '', // To be filled during profile setup
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await saveDoctorProfile(defaultProfile);
      return defaultProfile;
    } catch (e) {
      throw Exception('Failed to get or create doctor profile: $e');
    }
  }

  // Save doctor profile (creates or updates)
  Future<void> saveDoctorProfile(DoctorProfile doctorProfile) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(doctorProfile.uid)
          .set(doctorProfile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save doctor profile: $e');
    }
  }

  // Update doctor profile (requires document to exist)
  Future<void> updateDoctorProfile(DoctorProfile doctorProfile) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(doctorProfile.uid)
          .update(doctorProfile.toFirestore());
    } catch (e) {
      throw Exception('Failed to update doctor profile: $e');
    }
  }

  // Get all doctors with optional filters
  Future<List<DoctorProfile>> getDoctors({
    String? specialization,
    bool? isAvailable,
    String? location,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (specialization != null) {
        query = query.where('specializations', arrayContains: specialization);
      }

      if (isAvailable == true) {
        query = query.where('isActive', isEqualTo: true);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => DoctorProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get doctors: $e');
    }
  }

  // Search doctors by name or specialization
  Future<List<DoctorProfile>> searchDoctors(String searchTerm) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DoctorProfile.fromFirestore(doc))
          .where(
            (doctor) =>
                doctor.fullName.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                ) ||
                doctor.specializations.any(
                  (spec) =>
                      spec.toLowerCase().contains(searchTerm.toLowerCase()),
                ) ||
                doctor.hospitalAffiliation.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                ),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search doctors: $e');
    }
  }

  // Delete doctor profile
  Future<void> deleteDoctorProfile(String uid) async {
    try {
      await _firestore.collection(_collection).doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete doctor profile: $e');
    }
  }
}
