import 'package:cloud_firestore/cloud_firestore.dart';

class HospitalProfile {
  final String uid;
  final String name;
  final String address;
  final String? phoneNumber;
  final String? email;
  final String? website;
  final String? imageUrl;

  // Location
  final double? latitude;
  final double? longitude;

  // Hospital Information
  final String type; // General, Specialized, Emergency, etc.
  final List<String> services; // Emergency, ICU, Surgery, Maternity, etc.
  final List<String> specializations; // Cardiology, Neurology, etc.
  final int bedCapacity;
  final bool hasEmergency;
  final bool hasICU;
  final bool hasAmbulance;

  // Operational
  final Map<String, String> operatingHours; // day: "hours"
  final bool is24Hours;
  final bool isGovernment;
  final String? licenseNumber;

  // Ratings & Reviews
  final double rating;
  final int reviewCount;

  // Status
  final bool isActive;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HospitalProfile({
    required this.uid,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.email,
    this.website,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.type,
    required this.services,
    required this.specializations,
    required this.bedCapacity,
    required this.hasEmergency,
    required this.hasICU,
    required this.hasAmbulance,
    required this.operatingHours,
    required this.is24Hours,
    required this.isGovernment,
    this.licenseNumber,
    required this.rating,
    required this.reviewCount,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create from Firestore document
  factory HospitalProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HospitalProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      website: data['website'],
      imageUrl: data['imageUrl'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      type: data['type'] ?? 'General',
      services: List<String>.from(data['services'] ?? []),
      specializations: List<String>.from(data['specializations'] ?? []),
      bedCapacity: data['bedCapacity'] ?? 0,
      hasEmergency: data['hasEmergency'] ?? false,
      hasICU: data['hasICU'] ?? false,
      hasAmbulance: data['hasAmbulance'] ?? false,
      operatingHours: Map<String, String>.from(data['operatingHours'] ?? {}),
      is24Hours: data['is24Hours'] ?? false,
      isGovernment: data['isGovernment'] ?? false,
      licenseNumber: data['licenseNumber'],
      rating: data['rating']?.toDouble() ?? 0.0,
      reviewCount: data['reviewCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
      'services': services,
      'specializations': specializations,
      'bedCapacity': bedCapacity,
      'hasEmergency': hasEmergency,
      'hasICU': hasICU,
      'hasAmbulance': hasAmbulance,
      'operatingHours': operatingHours,
      'is24Hours': is24Hours,
      'isGovernment': isGovernment,
      'licenseNumber': licenseNumber,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copyable properties
  HospitalProfile copyWith({
    String? uid,
    String? name,
    String? address,
    String? phoneNumber,
    String? email,
    String? website,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? type,
    List<String>? services,
    List<String>? specializations,
    int? bedCapacity,
    bool? hasEmergency,
    bool? hasICU,
    bool? hasAmbulance,
    Map<String, String>? operatingHours,
    bool? is24Hours,
    bool? isGovernment,
    String? licenseNumber,
    double? rating,
    int? reviewCount,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HospitalProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      services: services ?? this.services,
      specializations: specializations ?? this.specializations,
      bedCapacity: bedCapacity ?? this.bedCapacity,
      hasEmergency: hasEmergency ?? this.hasEmergency,
      hasICU: hasICU ?? this.hasICU,
      hasAmbulance: hasAmbulance ?? this.hasAmbulance,
      operatingHours: operatingHours ?? this.operatingHours,
      is24Hours: is24Hours ?? this.is24Hours,
      isGovernment: isGovernment ?? this.isGovernment,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get display operating hours
  String getDisplayOperatingHours() {
    if (is24Hours) return '24 Hours';

    if (operatingHours.isEmpty) return 'Contact for hours';

    // Try to get today's hours
    final today = DateTime.now().weekday;
    final dayNames = [
      '',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final todayKey = dayNames[today];

    if (operatingHours.containsKey(todayKey)) {
      return 'Today: ${operatingHours[todayKey]}';
    }

    // Return first available hours
    final firstEntry = operatingHours.entries.first;
    return '${firstEntry.key}: ${firstEntry.value}';
  }

  // Check if hospital is currently open
  bool get isCurrentlyOpen {
    if (is24Hours) return true;

    final now = DateTime.now();
    final today = now.weekday;
    final dayNames = [
      '',
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final todayKey = dayNames[today];

    if (!operatingHours.containsKey(todayKey)) return false;

    final todayHours = operatingHours[todayKey]!;
    if (todayHours.toLowerCase().contains('closed')) return false;

    // Simple time checking - could be enhanced
    final currentHour = now.hour;
    return currentHour >= 8 &&
        currentHour <= 20; // Basic 8 AM - 8 PM assumption
  }

  // Get emergency availability status
  String get emergencyStatus {
    if (!hasEmergency) return 'No Emergency Services';
    if (is24Hours) return '24/7 Emergency';
    return 'Emergency Available';
  }
}
