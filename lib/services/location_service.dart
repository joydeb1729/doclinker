import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../models/doctor_profile.dart';
import '../models/hospital_profile.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationService {
  static const double _defaultRadius = 10.0; // 10 km default radius

  // Rate limiting for Overpass API
  static DateTime? _lastOSMRequest;
  static const Duration _minRequestInterval = Duration(seconds: 2);

  // Simple cache to avoid repeated identical requests
  static Map<String, List<HospitalProfile>> _osmCache = {};
  static DateTime? _cacheTime;

  /// Clear OSM cache - useful when user wants fresh data
  static void clearOSMCache() {
    _osmCache.clear();
    _cacheTime = null;
    print('LocationService: OSM cache cleared');
  }

  /// Get current user location
  static Future<LocationResult?> getCurrentLocation() async {
    try {
      print('LocationService: Starting location acquisition...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('LocationService: Location services are disabled');
        return null;
      }

      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('LocationService: Location permission denied');
        return null;
      }

      print('LocationService: Getting GPS position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print(
        'LocationService: Got position: ${position.latitude}, ${position.longitude}',
      );

      // Check if the location seems to be a default/mock location (Google HQ, etc.)
      if (_isLikelyMockLocation(position.latitude, position.longitude)) {
        print(
          'LocationService: Detected possible mock/default location, trying alternative method...',
        );

        // Try to get last known position
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null &&
            !_isLikelyMockLocation(
              lastPosition.latitude,
              lastPosition.longitude,
            )) {
          position = lastPosition;
          print(
            'LocationService: Using last known position: ${position.latitude}, ${position.longitude}',
          );
        } else {
          print(
            'LocationService: No valid last known position, using Bangladesh location',
          );
          // If we're getting a mock location and no valid last position, use Bangladesh
          return LocationResult(
            latitude: 22.8456, // Khulna, Bangladesh
            longitude: 89.5403,
            address: 'Khulna, Bangladesh (Approximate)',
          );
        }
      }

      // For address, we'll use a simple format
      // In a real app, you might use geocoding to get actual address
      String address =
          'Lat: ${position.latitude.toStringAsFixed(4)}, '
          'Lng: ${position.longitude.toStringAsFixed(4)}';

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      print('LocationService: Error getting location: $e');
      return null;
    }
  }

  /// Check and request location permissions
  static Future<bool> requestLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('LocationService: Location services enabled: $serviceEnabled');
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    print('LocationService: Current permission: $permission');

    if (permission == LocationPermission.denied) {
      print('LocationService: Requesting permission...');
      permission = await Geolocator.requestPermission();
      print('LocationService: Permission after request: $permission');
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('LocationService: Permission denied forever');
      return false;
    }

    print('LocationService: Permission granted');
    return true;
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Get nearby doctors from Firebase based on current location
  static Future<List<DoctorProfile>> getNearbyDoctors({
    required double userLatitude,
    required double userLongitude,
    double radiusKm = _defaultRadius,
    String? specialty,
  }) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Get all doctors from Firebase
      Query query = firestore
          .collection('doctor_profiles')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true);

      // Add specialty filter if provided
      if (specialty != null && specialty != 'All') {
        query = query.where('specializations', arrayContains: specialty);
      }

      final QuerySnapshot snapshot = await query.get();

      List<DoctorProfile> nearbyDoctors = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Check if doctor has location data
          final lat = data['latitude'];
          final lng = data['longitude'];

          if (lat != null && lng != null) {
            double distance = calculateDistance(
              userLatitude,
              userLongitude,
              lat.toDouble(),
              lng.toDouble(),
            );

            // Only include doctors within the specified radius
            if (distance <= radiusKm) {
              DoctorProfile doctor = DoctorProfile.fromFirestore(doc);
              nearbyDoctors.add(doctor);
            }
          }
        } catch (e) {
          print('Error parsing doctor data: $e');
          continue;
        }
      }

      // Sort by distance
      nearbyDoctors.sort((a, b) {
        double distanceA = calculateDistance(
          userLatitude,
          userLongitude,
          a.latitude ?? 0,
          a.longitude ?? 0,
        );
        double distanceB = calculateDistance(
          userLatitude,
          userLongitude,
          b.latitude ?? 0,
          b.longitude ?? 0,
        );
        return distanceA.compareTo(distanceB);
      });

      return nearbyDoctors;
    } catch (e) {
      print('Error getting nearby doctors: $e');
      return [];
    }
  }

  /// Get nearby hospitals within the specified radius
  static Future<List<HospitalProfile>> getNearbyHospitals(
    double userLatitude,
    double userLongitude, {
    double radiusInKm = _defaultRadius,
    int limit = 50,
    String? serviceFilter, // 'emergency', 'icu', 'ambulance', etc.
    String? typeFilter, // 'government', 'private', etc.
  }) async {
    try {
      print(
        'LocationService: Searching for hospitals near $userLatitude, $userLongitude within ${radiusInKm}km',
      );

      // Primary: Get real hospitals from OpenStreetMap (ensures accurate radius)
      print('LocationService: Fetching hospitals from OpenStreetMap...');
      List<HospitalProfile> osmHospitals = await _getOpenStreetMapHospitals(
        userLatitude,
        userLongitude,
        radiusInKm: radiusInKm,
        limit: limit,
      );

      // Fallback: Get hospitals from Firebase if OSM fails or returns few results
      List<HospitalProfile> firebaseHospitals = [];
      if (osmHospitals.length < 5) {
        print(
          'LocationService: OSM returned ${osmHospitals.length} hospitals, supplementing with Firebase...',
        );
        firebaseHospitals = await _getFirebaseHospitals(
          userLatitude,
          userLongitude,
          radiusInKm: radiusInKm,
          limit: limit,
          serviceFilter: serviceFilter,
          typeFilter: typeFilter,
        );
      }

      // Combine results (OSM hospitals first, then Firebase as supplement)
      List<HospitalProfile> allHospitals = [...osmHospitals];

      // Add Firebase hospitals that aren't already in our list
      for (var firebaseHospital in firebaseHospitals) {
        bool isDuplicate = allHospitals.any(
          (h) =>
              calculateDistance(
                h.latitude ?? 0,
                h.longitude ?? 0,
                firebaseHospital.latitude ?? 0,
                firebaseHospital.longitude ?? 0,
              ) <
              0.1, // within 100m
        );
        if (!isDuplicate) {
          allHospitals.add(firebaseHospital);
        }
      }

      // Sort by distance and limit results
      allHospitals.sort((a, b) {
        double distanceA = calculateDistance(
          userLatitude,
          userLongitude,
          a.latitude ?? 0,
          a.longitude ?? 0,
        );
        double distanceB = calculateDistance(
          userLatitude,
          userLongitude,
          b.latitude ?? 0,
          b.longitude ?? 0,
        );
        return distanceA.compareTo(distanceB);
      });

      List<HospitalProfile> result = allHospitals.take(limit).toList();
      print(
        'LocationService: Returning ${result.length} hospitals (${osmHospitals.length} from OSM + ${firebaseHospitals.length} from Firebase)',
      );
      return result;
    } catch (e) {
      print('Error getting nearby hospitals: $e');
      return [];
    }
  }

  /// Get hospitals from Firebase database
  static Future<List<HospitalProfile>> _getFirebaseHospitals(
    double userLatitude,
    double userLongitude, {
    double radiusInKm = _defaultRadius,
    int limit = 50,
    String? serviceFilter,
    String? typeFilter,
  }) async {
    try {
      Query query = FirebaseFirestore.instance
          .collection('hospitals')
          .where('isActive', isEqualTo: true)
          .where('latitude', isNotEqualTo: null)
          .where('longitude', isNotEqualTo: null)
          .limit(limit);

      // Add service filter if specified
      if (serviceFilter != null) {
        switch (serviceFilter.toLowerCase()) {
          case 'emergency':
            query = query.where('hasEmergency', isEqualTo: true);
            break;
          case 'icu':
            query = query.where('hasICU', isEqualTo: true);
            break;
          case 'ambulance':
            query = query.where('hasAmbulance', isEqualTo: true);
            break;
          case '24hours':
            query = query.where('is24Hours', isEqualTo: true);
            break;
        }
      }

      // Add type filter if specified
      if (typeFilter != null) {
        if (typeFilter.toLowerCase() == 'government') {
          query = query.where('isGovernment', isEqualTo: true);
        } else if (typeFilter.toLowerCase() == 'private') {
          query = query.where('isGovernment', isEqualTo: false);
        }
      }

      final QuerySnapshot snapshot = await query.get();
      List<HospitalProfile> nearbyHospitals = [];

      for (DocumentSnapshot doc in snapshot.docs) {
        try {
          final hospital = HospitalProfile.fromDocument(doc);

          if (hospital.latitude != null && hospital.longitude != null) {
            double distance = calculateDistance(
              userLatitude,
              userLongitude,
              hospital.latitude!,
              hospital.longitude!,
            );

            if (distance <= radiusInKm) {
              nearbyHospitals.add(hospital);
            }
          }
        } catch (e) {
          print('Error parsing hospital document ${doc.id}: $e');
        }
      }

      return nearbyHospitals;
    } catch (e) {
      print('Error getting Firebase hospitals: $e');
      return [];
    }
  }

  /// Get hospitals from OpenStreetMap using Overpass API
  static Future<List<HospitalProfile>> _getOpenStreetMapHospitals(
    double userLatitude,
    double userLongitude, {
    double radiusInKm = _defaultRadius,
    int limit = 50,
  }) async {
    try {
      // Create cache key for this request
      String cacheKey =
          '${userLatitude.toStringAsFixed(4)}_${userLongitude.toStringAsFixed(4)}_${radiusInKm}';

      // Check cache first (valid for 5 minutes)
      if (_osmCache.containsKey(cacheKey) &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < Duration(minutes: 5)) {
        print(
          'LocationService: Using cached OSM data (${_osmCache[cacheKey]!.length} hospitals)',
        );
        return _osmCache[cacheKey]!;
      }

      // Rate limiting - wait if we made a request too recently
      if (_lastOSMRequest != null) {
        final timeSinceLastRequest = DateTime.now().difference(
          _lastOSMRequest!,
        );
        if (timeSinceLastRequest < _minRequestInterval) {
          final waitTime = _minRequestInterval - timeSinceLastRequest;
          print(
            'LocationService: Rate limiting - waiting ${waitTime.inMilliseconds}ms...',
          );
          await Future.delayed(waitTime);
        }
      }

      // Convert radius from km to meters for Overpass API
      int radiusInMeters = (radiusInKm * 1000).round();

      print('LocationService: OSM Search Parameters:');
      print('  - Radius: ${radiusInKm}km = ${radiusInMeters}m');
      print('  - Location: $userLatitude, $userLongitude');

      const String overpassUrl = "https://overpass-api.de/api/interpreter";

      // Overpass query to get hospitals
      String query =
          """
[out:json][timeout:25];
(
  node["amenity"="hospital"](around:$radiusInMeters,$userLatitude,$userLongitude);
  way["amenity"="hospital"](around:$radiusInMeters,$userLatitude,$userLongitude);
  relation["amenity"="hospital"](around:$radiusInMeters,$userLatitude,$userLongitude);
);
out center;
""";

      print('LocationService: Querying OpenStreetMap for hospitals...');
      print(
        'OSM Query: ${query.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ')}',
      );

      // Update last request time
      _lastOSMRequest = DateTime.now();

      final response = await http
          .post(
            Uri.parse(overpassUrl),
            body: {'data': query},
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 429) {
        print(
          'LocationService: Rate limited by Overpass API - using cached data or Firebase fallback',
        );
        // Return cached data if available, otherwise empty list to trigger Firebase fallback
        return _osmCache[cacheKey] ?? [];
      } else if (response.statusCode != 200) {
        print(
          'LocationService: Overpass API error: ${response.statusCode} - ${response.reasonPhrase}',
        );
        return _osmCache[cacheKey] ?? []; // Try cached data
      }

      final data = json.decode(response.body);
      final elements = data['elements'] as List<dynamic>? ?? [];

      print(
        'LocationService: Found ${elements.length} hospitals from OpenStreetMap',
      );

      List<HospitalProfile> hospitals = [];

      for (var element in elements) {
        try {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          String? name = tags['name'] as String?;

          // Skip if no name
          if (name == null || name.trim().isEmpty) {
            name = 'Hospital'; // Default name
          }

          // Get coordinates
          double? lat, lon;
          if (element.containsKey('center')) {
            lat = element['center']['lat']?.toDouble();
            lon = element['center']['lon']?.toDouble();
          } else {
            lat = element['lat']?.toDouble();
            lon = element['lon']?.toDouble();
          }

          if (lat == null || lon == null) continue;

          // Calculate distance to ensure it's within radius
          double distance = calculateDistance(
            userLatitude,
            userLongitude,
            lat,
            lon,
          );
          if (distance > radiusInKm) continue;

          // Create hospital profile from OSM data
          HospitalProfile hospital = HospitalProfile(
            uid: 'osm_${element['id']}',
            name: name,
            address:
                tags['addr:full'] as String? ??
                '${tags['addr:street'] ?? ''} ${tags['addr:city'] ?? ''}'
                    .trim(),
            phoneNumber:
                tags['phone'] as String? ?? tags['contact:phone'] as String?,
            email: tags['email'] as String? ?? tags['contact:email'] as String?,
            website:
                tags['website'] as String? ??
                tags['contact:website'] as String?,
            latitude: lat,
            longitude: lon,
            type: tags['healthcare:speciality'] != null
                ? 'Specialized'
                : 'General',
            services: _extractServicesFromTags(tags),
            specializations: _extractSpecializationsFromTags(tags),
            bedCapacity:
                _extractBedsFromTags(tags) ?? 50, // Default bed capacity
            operatingHours: _extractOperatingHours(tags),
            rating: 4.0, // Default rating for OSM hospitals
            reviewCount: 0,
            isGovernment:
                tags['operator:type'] == 'public' ||
                tags['healthcare:system'] == 'public',
            hasEmergency:
                tags['emergency'] == 'yes' ||
                tags['healthcare:speciality']?.toString().contains(
                      'emergency',
                    ) ==
                    true,
            hasICU:
                tags['healthcare:speciality']?.toString().contains(
                  'intensive_care',
                ) ==
                true,
            hasAmbulance: tags['ambulance'] == 'yes',
            is24Hours: tags['opening_hours'] == '24/7',
            isActive: true,
            isVerified: false, // OSM data is not verified by default
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          hospitals.add(hospital);
        } catch (e) {
          print('LocationService: Error parsing OSM hospital: $e');
          continue;
        }
      }

      // Sort by distance and limit
      hospitals.sort((a, b) {
        double distanceA = calculateDistance(
          userLatitude,
          userLongitude,
          a.latitude!,
          a.longitude!,
        );
        double distanceB = calculateDistance(
          userLatitude,
          userLongitude,
          b.latitude!,
          b.longitude!,
        );
        return distanceA.compareTo(distanceB);
      });

      List<HospitalProfile> result = hospitals.take(limit).toList();

      // Cache the results
      _osmCache[cacheKey] = result;
      _cacheTime = DateTime.now();

      return result;
    } catch (e) {
      print('LocationService: Error getting OSM hospitals: $e');
      return [];
    }
  }

  /// Extract services from OSM tags
  static List<String> _extractServicesFromTags(Map<String, dynamic> tags) {
    List<String> services = [];

    if (tags['emergency'] == 'yes') services.add('Emergency');
    if (tags['healthcare:speciality']?.toString().contains('cardiology') ==
        true)
      services.add('Cardiology');
    if (tags['healthcare:speciality']?.toString().contains('neurology') == true)
      services.add('Neurology');
    if (tags['healthcare:speciality']?.toString().contains('orthopedic') ==
        true)
      services.add('Orthopedics');
    if (tags['healthcare:speciality']?.toString().contains('pediatric') == true)
      services.add('Pediatrics');
    if (tags['healthcare:speciality']?.toString().contains('gynecology') ==
        true)
      services.add('Gynecology');

    return services.isEmpty ? ['General Medicine'] : services;
  }

  /// Extract specializations from OSM tags
  static List<String> _extractSpecializationsFromTags(
    Map<String, dynamic> tags,
  ) {
    List<String> specs = [];

    String? speciality = tags['healthcare:speciality'] as String?;
    if (speciality != null) {
      // Split by common delimiters and clean up
      specs = speciality
          .split(RegExp(r'[;,|]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return specs.isEmpty ? ['General Medicine'] : specs;
  }

  /// Extract bed count from OSM tags
  static int? _extractBedsFromTags(Map<String, dynamic> tags) {
    String? beds = tags['beds'] as String?;
    if (beds != null) {
      return int.tryParse(beds);
    }
    return null;
  }

  /// Extract operating hours from OSM tags
  static Map<String, String> _extractOperatingHours(Map<String, dynamic> tags) {
    String? openingHours = tags['opening_hours'] as String?;

    if (openingHours == '24/7') {
      return {
        'Monday': '24 Hours',
        'Tuesday': '24 Hours',
        'Wednesday': '24 Hours',
        'Thursday': '24 Hours',
        'Friday': '24 Hours',
        'Saturday': '24 Hours',
        'Sunday': '24 Hours',
      };
    }

    // Default operating hours for hospitals
    return {
      'Monday': '8:00 AM - 6:00 PM',
      'Tuesday': '8:00 AM - 6:00 PM',
      'Wednesday': '8:00 AM - 6:00 PM',
      'Thursday': '8:00 AM - 6:00 PM',
      'Friday': '8:00 AM - 6:00 PM',
      'Saturday': '8:00 AM - 2:00 PM',
      'Sunday': 'Emergency Only',
    };
  }

  /// Get distance to a specific doctor
  static double getDistanceToDoctor(
    double userLatitude,
    double userLongitude,
    DoctorProfile doctor,
  ) {
    if (doctor.latitude == null || doctor.longitude == null) {
      return double.infinity;
    }

    return calculateDistance(
      userLatitude,
      userLongitude,
      doctor.latitude!,
      doctor.longitude!,
    );
  }

  /// Get distance to a specific hospital
  static double getDistanceToHospital(
    double userLatitude,
    double userLongitude,
    HospitalProfile hospital,
  ) {
    if (hospital.latitude == null || hospital.longitude == null) {
      return double.infinity;
    }

    return calculateDistance(
      userLatitude,
      userLongitude,
      hospital.latitude!,
      hospital.longitude!,
    );
  }

  /// Check if location services are available
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Open app settings for permission management
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Check if coordinates are likely mock/default locations
  static bool _isLikelyMockLocation(double latitude, double longitude) {
    // Common mock/default locations to detect
    List<List<double>> mockLocations = [
      [37.4219983, -122.084], // Google HQ, Mountain View, CA
      [37.785834, -122.406417], // San Francisco, CA
      [40.7589, -73.9851], // New York, NY
      [0.0, 0.0], // Null Island
      [37.4220656, -122.0840897], // Google HQ variations
    ];

    // Check if current location matches any known mock locations (within ~100m)
    for (List<double> mockLoc in mockLocations) {
      double distance = calculateDistance(
        latitude,
        longitude,
        mockLoc[0],
        mockLoc[1],
      );
      if (distance < 0.1) {
        // Less than 100 meters
        return true;
      }
    }

    return false;
  }

  /// Get mock location for testing (fallback)
  static LocationResult getMockLocation() {
    // Khulna, Bangladesh coordinates as default for Bangladesh users
    return const LocationResult(
      latitude: 22.8456,
      longitude: 89.5403,
      address: 'Khulna, Bangladesh',
    );
  }
}
