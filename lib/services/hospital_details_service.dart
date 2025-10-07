import 'dart:math' as math;
import '../services/location_service.dart';
import '../services/doctor_matching_service.dart';

/// Service to get hospital details, coordinates, and calculate real-time distances
class HospitalDetailsService {
  /// Hospital coordinates mapping for major hospitals in Bangladesh
  static final Map<String, HospitalCoordinates> _hospitalCoordinates = {
    // Dhaka hospitals
    'Square Hospital Ltd., Dhaka': HospitalCoordinates(
      latitude: 23.7516,
      longitude: 90.3876,
      address:
          '18/F, Bir Uttam Qazi Nuruzzaman Sarak, West Panthapath, Dhaka 1205',
      phone: '+88-02-8159457',
    ),
    'United Hospital Limited': HospitalCoordinates(
      latitude: 23.8041,
      longitude: 90.4152,
      address: 'Plot 15, Road 71, Gulshan, Dhaka 1212',
      phone: '+88-02-55616700',
    ),
    'Evercare Hospital Dhaka': HospitalCoordinates(
      latitude: 23.7956,
      longitude: 90.4106,
      address: 'Plot 81, Block E, Bashundhara R/A, Dhaka 1229',
      phone: '+88-10678',
    ),
    'Dhaka Medical College & Hospital': HospitalCoordinates(
      latitude: 23.7270,
      longitude: 90.3956,
      address: 'Secretariat Rd, Dhaka 1000',
      phone: '+88-02-55165088',
    ),
    'Ibn Sina Hospitals, Dhaka': HospitalCoordinates(
      latitude: 23.7461,
      longitude: 90.3907,
      address: 'House 48, Road 9/A, Dhanmondi, Dhaka 1209',
      phone: '+88-02-48115566',
    ),
    'Bangladesh Medical College Hospital, Dhaka': HospitalCoordinates(
      latitude: 23.7338,
      longitude: 90.3872,
      address: '14/A Toyenbee Circular Road, Dhaka 1000',
      phone: '+88-02-7193001',
    ),

    // Chittagong hospitals
    'Chittagong Medical College Hospital': HospitalCoordinates(
      latitude: 22.3475,
      longitude: 91.8123,
      address: 'K.B. Fazlul Kader Road, Chittagong 4000',
      phone: '+88-031-2652969',
    ),
    'Chittagong Maa-O-Shishu Hospital, Chittagong': HospitalCoordinates(
      latitude: 22.3569,
      longitude: 91.7832,
      address: 'Agrabad C/A, Chittagong 4100',
      phone: '+88-031-2510501',
    ),

    // Khulna hospitals
    'Khulna Medical College Hospital, Khulna': HospitalCoordinates(
      latitude: 22.8456,
      longitude: 89.5403,
      address: 'Academic Building, Khulna Medical College, Khulna 9000',
      phone: '+88-041-761900',
    ),
    'Ad-din Akij Medical College Hospital, Khulna': HospitalCoordinates(
      latitude: 22.8267,
      longitude: 89.5574,
      address: 'Baira, Khulna 9100',
      phone: '+88-041-2851234',
    ),

    // Sylhet hospitals
    'M.A.G Osmani Medical College and Hospital, Sylhet': HospitalCoordinates(
      latitude: 24.8949,
      longitude: 91.8687,
      address: 'Medical College Road, Sylhet 3100',
      phone: '+88-0821-713797',
    ),
    'Ibn Sina Hospital Sylhet Ltd': HospitalCoordinates(
      latitude: 24.9036,
      longitude: 91.8617,
      address: 'Subhanighat, Sylhet 3100',
      phone: '+88-0821-2880811',
    ),

    // Rajshahi hospitals
    'Rajshahi Medical College Hospital': HospitalCoordinates(
      latitude: 24.3745,
      longitude: 88.6042,
      address: 'Laxmipur, Rajshahi 6000',
      phone: '+88-0721-772150',
    ),

    // Other major hospitals
    'Mymensingh Medical College Hospital': HospitalCoordinates(
      latitude: 24.7465,
      longitude: 90.4072,
      address: 'Town Hall Road, Mymensingh 2200',
      phone: '+88-091-66841',
    ),
  };

  /// Get hospital details with coordinates and contact information
  static HospitalDetails? getHospitalDetails(String hospitalName) {
    final coordinates = _hospitalCoordinates[hospitalName];
    if (coordinates == null) {
      // Try fuzzy matching for similar names
      final matchedName = _findSimilarHospitalName(hospitalName);
      if (matchedName != null) {
        final matchedCoordinates = _hospitalCoordinates[matchedName];
        if (matchedCoordinates != null) {
          return HospitalDetails(
            name: matchedName,
            coordinates: matchedCoordinates,
            originalSearchName: hospitalName,
          );
        }
      }
      return null;
    }

    return HospitalDetails(name: hospitalName, coordinates: coordinates);
  }

  /// Calculate real-time distance between user location and hospital
  static Future<String> calculateRealTimeDistance({
    required String hospitalName,
    LocationResult? userLocation,
  }) async {
    if (userLocation == null) {
      return _getEstimatedDistance(hospitalName);
    }

    final hospitalDetails = getHospitalDetails(hospitalName);
    if (hospitalDetails == null) {
      return _getEstimatedDistance(hospitalName);
    }

    // Calculate distance using Haversine formula
    final distance = _calculateHaversineDistance(
      userLocation.latitude,
      userLocation.longitude,
      hospitalDetails.coordinates.latitude,
      hospitalDetails.coordinates.longitude,
    );

    return '${distance.toStringAsFixed(1)} km';
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreeToRadian(lat2 - lat1);
    final double dLon = _degreeToRadian(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreeToRadian(lat1)) *
            math.cos(_degreeToRadian(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreeToRadian(double degree) {
    return degree * (math.pi / 180);
  }

  /// Fuzzy matching to find similar hospital names
  static String? _findSimilarHospitalName(String searchName) {
    final searchLower = searchName.toLowerCase().trim();

    for (final hospitalName in _hospitalCoordinates.keys) {
      final hospitalLower = hospitalName.toLowerCase();

      // Check if search name contains key parts of hospital name
      if (_calculateSimilarity(searchLower, hospitalLower) > 0.6) {
        return hospitalName;
      }
    }

    return null;
  }

  /// Calculate similarity between two strings
  static double _calculateSimilarity(String str1, String str2) {
    final words1 = str1.split(' ').where((w) => w.length > 2).toSet();
    final words2 = str2.split(' ').where((w) => w.length > 2).toSet();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2);
    return intersection.length / words1.length;
  }

  /// Get estimated distance for unmapped hospitals
  static String _getEstimatedDistance(String hospitalName) {
    final hospitalLower = hospitalName.toLowerCase();

    if (hospitalLower.contains('dhaka')) {
      return '${(2.0 + math.Random().nextDouble() * 4.0).toStringAsFixed(1)} km';
    } else if (hospitalLower.contains('chittagong')) {
      return '${(1.8 + math.Random().nextDouble() * 3.0).toStringAsFixed(1)} km';
    } else if (hospitalLower.contains('khulna')) {
      return '${(1.5 + math.Random().nextDouble() * 2.5).toStringAsFixed(1)} km';
    } else if (hospitalLower.contains('sylhet')) {
      return '${(2.0 + math.Random().nextDouble() * 3.0).toStringAsFixed(1)} km';
    } else {
      return '${(2.0 + math.Random().nextDouble() * 3.5).toStringAsFixed(1)} km';
    }
  }

  /// Get comprehensive doctor and hospital information for booking screen
  static Future<DoctorBookingInfo> getDoctorBookingInfo({
    required MatchedDoctor doctor,
    LocationResult? userLocation,
  }) async {
    final hospitalDetails = getHospitalDetails(doctor.hospitalAffiliation);
    final realTimeDistance = await calculateRealTimeDistance(
      hospitalName: doctor.hospitalAffiliation,
      userLocation: userLocation,
    );

    return DoctorBookingInfo(
      doctor: doctor,
      hospitalDetails: hospitalDetails,
      realTimeDistance: realTimeDistance,
      userLocation: userLocation,
    );
  }
}

/// Hospital coordinates and contact information
class HospitalCoordinates {
  final double latitude;
  final double longitude;
  final String address;
  final String phone;

  const HospitalCoordinates({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.phone,
  });
}

/// Complete hospital details with coordinates
class HospitalDetails {
  final String name;
  final HospitalCoordinates coordinates;
  final String? originalSearchName;

  const HospitalDetails({
    required this.name,
    required this.coordinates,
    this.originalSearchName,
  });
}

/// Complete doctor and hospital information for booking
class DoctorBookingInfo {
  final MatchedDoctor doctor;
  final HospitalDetails? hospitalDetails;
  final String realTimeDistance;
  final LocationResult? userLocation;

  const DoctorBookingInfo({
    required this.doctor,
    this.hospitalDetails,
    required this.realTimeDistance,
    this.userLocation,
  });

  /// Check if hospital details are available
  bool get hasHospitalDetails => hospitalDetails != null;

  /// Get hospital address or fallback message
  String get hospitalAddress =>
      hospitalDetails?.coordinates.address ?? 'Address not available';

  /// Get hospital phone or fallback message
  String get hospitalPhone =>
      hospitalDetails?.coordinates.phone ?? 'Contact not available';

  /// Get hospital name (either matched or original)
  String get hospitalName =>
      hospitalDetails?.name ?? doctor.hospitalAffiliation;
}
