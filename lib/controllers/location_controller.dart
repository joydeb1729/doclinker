import 'package:flutter/material.dart';
import '../models/doctor_profile.dart';
import '../models/hospital_profile.dart';
import '../services/location_service.dart';

class LocationController extends ChangeNotifier {
  DoctorProfile? _selectedDoctor;
  HospitalProfile? _selectedHospital;
  LocationResult? _userLocation;
  List<DoctorProfile> _recentDoctors = [];
  List<DoctorProfile> _nearbyDoctors = [];
  List<HospitalProfile> _nearbyHospitals = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedSpecialty = 'All';
  String _searchMode = 'doctors'; // 'doctors', 'hospitals', 'both'

  // Getters
  DoctorProfile? get selectedDoctor => _selectedDoctor;
  HospitalProfile? get selectedHospital => _selectedHospital;
  LocationResult? get userLocation => _userLocation;
  List<DoctorProfile> get recentDoctors => _recentDoctors;
  List<DoctorProfile> get nearbyDoctors => _nearbyDoctors;
  List<HospitalProfile> get nearbyHospitals => _nearbyHospitals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedSpecialty => _selectedSpecialty;
  String get searchMode => _searchMode;

  // Set selected doctor
  void setSelectedDoctor(DoctorProfile doctor) {
    _selectedDoctor = doctor;
    _selectedHospital = null; // Clear hospital selection

    // Add to recent doctors if not already there
    if (!_recentDoctors.any((d) => d.uid == doctor.uid)) {
      _recentDoctors.insert(0, doctor);
      if (_recentDoctors.length > 5) {
        _recentDoctors.removeLast();
      }
    }

    notifyListeners();
  }

  // Set selected hospital
  void setSelectedHospital(HospitalProfile hospital) {
    _selectedHospital = hospital;
    _selectedDoctor = null; // Clear doctor selection
    notifyListeners();
  }

  // Set search mode
  void setSearchMode(String mode) {
    if (_searchMode != mode) {
      _searchMode = mode;
      _selectedDoctor = null;
      _selectedHospital = null;
      // Refresh results with new mode
      if (_userLocation != null) {
        refreshNearbyResults();
      }
      notifyListeners();
    }
  }

  // Set user location
  void setUserLocation(LocationResult location) {
    _userLocation = location;
    notifyListeners();
  }

  // Set selected specialty for filtering
  void setSelectedSpecialty(String specialty) {
    _selectedSpecialty = specialty;
    notifyListeners();
  }

  // Use my location (real GPS)
  Future<void> useMyLocation() async {
    print('LocationController: Starting useMyLocation()...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if location services are available first
      bool servicesEnabled = await LocationService.isLocationServiceEnabled();
      if (!servicesEnabled) {
        _errorMessage =
            'Location services are disabled. Please enable GPS in your device settings.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get user's current location
      LocationResult? location = await LocationService.getCurrentLocation();

      if (location != null) {
        print(
          'LocationController: Got real location: ${location.latitude}, ${location.longitude}',
        );
        _userLocation = location;

        // Get nearby doctors based on location
        await _loadNearbyDoctors();
      } else {
        _errorMessage =
            'Unable to get your location. Please check location permissions and try again.';
        print('LocationController: Failed to get location, using fallback...');
        // Fallback to mock location for demo
        _userLocation = LocationService.getMockLocation();
        await _loadNearbyDoctors();
      }
    } catch (e) {
      print('LocationController: Exception during location fetch: $e');
      _errorMessage =
          'Error getting location: Please enable location services and permissions.';
      // Fallback to mock location
      _userLocation = LocationService.getMockLocation();
      await _loadNearbyDoctors();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load nearby doctors from Firebase
  Future<void> _loadNearbyDoctors() async {
    if (_userLocation == null) return;

    try {
      _nearbyDoctors = await LocationService.getNearbyDoctors(
        userLatitude: _userLocation!.latitude,
        userLongitude: _userLocation!.longitude,
        specialty: _selectedSpecialty == 'All' ? null : _selectedSpecialty,
      );
    } catch (e) {
      _errorMessage = 'Error loading nearby doctors: ${e.toString()}';
      _nearbyDoctors = [];
    }
  }

  // Refresh nearby doctors with current filters
  Future<void> refreshNearbyDoctors() async {
    if (_userLocation == null) {
      await useMyLocation();
      return;
    }

    _isLoading = true;
    notifyListeners();

    await _loadNearbyDoctors();

    _isLoading = false;
    notifyListeners();
  }

  // Load nearby hospitals from Firebase
  Future<void> _loadNearbyHospitals() async {
    if (_userLocation == null) return;

    try {
      _nearbyHospitals = await LocationService.getNearbyHospitals(
        _userLocation!.latitude,
        _userLocation!.longitude,
        serviceFilter: _selectedSpecialty == 'All' ? null : _selectedSpecialty,
      );
    } catch (e) {
      _errorMessage = 'Error loading nearby hospitals: ${e.toString()}';
      _nearbyHospitals = [];
    }
  }

  // Refresh nearby hospitals
  Future<void> refreshNearbyHospitals() async {
    if (_userLocation == null) {
      await useMyLocation();
      return;
    }

    _isLoading = true;
    notifyListeners();

    await _loadNearbyHospitals();

    _isLoading = false;
    notifyListeners();
  }

  // Refresh nearby results based on current search mode
  Future<void> refreshNearbyResults() async {
    if (_searchMode == 'doctors') {
      await refreshNearbyDoctors();
    } else if (_searchMode == 'hospitals') {
      await refreshNearbyHospitals();
    } else if (_searchMode == 'both') {
      // Refresh both in parallel
      _isLoading = true;
      notifyListeners();

      await Future.wait([_loadNearbyDoctors(), _loadNearbyHospitals()]);

      _isLoading = false;
      notifyListeners();
    }
  }

  // Search doctors
  List<DoctorProfile> searchDoctors(String query) {
    if (query.isEmpty) return _nearbyDoctors;

    return _nearbyDoctors.where((doctor) {
      final searchQuery = query.toLowerCase();
      return doctor.fullName.toLowerCase().contains(searchQuery) ||
          doctor.clinicAddress.toLowerCase().contains(searchQuery) ||
          doctor.specializations.any(
            (specialty) => specialty.toLowerCase().contains(searchQuery),
          ) ||
          doctor.hospitalAffiliation.toLowerCase().contains(searchQuery);
    }).toList();
  }

  // Filter doctors by specialty
  Future<void> filterBySpecialty(String specialty) async {
    _selectedSpecialty = specialty;

    if (_userLocation != null) {
      _isLoading = true;
      notifyListeners();

      await _loadNearbyDoctors();

      _isLoading = false;
    }

    notifyListeners();
  }

  // Clear selected doctor
  void clearSelectedDoctor() {
    _selectedDoctor = null;
    notifyListeners();
  }

  // Get doctor by ID
  DoctorProfile? getDoctorById(String id) {
    try {
      return _nearbyDoctors.firstWhere((doctor) => doctor.uid == id);
    } catch (e) {
      return null;
    }
  }

  // Get doctors by specialty from current results
  List<DoctorProfile> getDoctorsBySpecialty(String specialty) {
    return _nearbyDoctors
        .where((doctor) => doctor.specializations.contains(specialty))
        .toList();
  }

  // Get distance to a specific doctor
  double getDistanceToDoctor(DoctorProfile doctor) {
    if (_userLocation == null) return double.infinity;

    return LocationService.getDistanceToDoctor(
      _userLocation!.latitude,
      _userLocation!.longitude,
      doctor,
    );
  }

  // Get context string for AI chat
  String getLocationContext() {
    if (_selectedDoctor != null) {
      double distance = getDistanceToDoctor(_selectedDoctor!);
      return 'Doctor: ${_selectedDoctor!.fullName} at ${_selectedDoctor!.hospitalAffiliation} '
          '(${distance.toStringAsFixed(1)}km away)';
    } else if (_userLocation != null) {
      return 'Location: ${_userLocation!.address}';
    }
    return 'No location selected';
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Check if location services are enabled
  Future<bool> checkLocationServices() async {
    return await LocationService.isLocationServiceEnabled();
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await LocationService.openLocationSettings();
  }

  // Open app settings for permissions
  Future<void> openAppSettings() async {
    await LocationService.openAppSettings();
  }
}
