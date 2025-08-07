import 'package:flutter/material.dart';

class Hospital {
  final String id;
  final String name;
  final String address;
  final double distance; // in km
  final List<String> specialties;
  final double rating;
  final bool isAvailable;

  Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    required this.specialties,
    required this.rating,
    required this.isAvailable,
  });
}

class LocationController extends ChangeNotifier {
  Hospital? _selectedHospital;
  String? _userLocation;
  List<Hospital> _recentHospitals = [];
  List<Hospital> _nearbyHospitals = [];
  bool _isLoading = false;

  // Getters
  Hospital? get selectedHospital => _selectedHospital;
  String? get userLocation => _userLocation;
  List<Hospital> get recentHospitals => _recentHospitals;
  List<Hospital> get nearbyHospitals => _nearbyHospitals;
  bool get isLoading => _isLoading;

  // Mock data for hospitals
  static final List<Hospital> _mockHospitals = [
    Hospital(
      id: '1',
      name: 'City General Hospital',
      address: '123 Main St, Downtown',
      distance: 2.3,
      specialties: ['Cardiology', 'Neurology', 'General Medicine'],
      rating: 4.8,
      isAvailable: true,
    ),
    Hospital(
      id: '2',
      name: 'Medical Center East',
      address: '456 Oak Ave, Eastside',
      distance: 1.8,
      specialties: ['Dermatology', 'Orthopedics', 'Pediatrics'],
      rating: 4.6,
      isAvailable: true,
    ),
    Hospital(
      id: '3',
      name: 'University Medical Center',
      address: '789 University Blvd',
      distance: 3.1,
      specialties: ['Oncology', 'Surgery', 'Emergency Medicine'],
      rating: 4.9,
      isAvailable: true,
    ),
    Hospital(
      id: '4',
      name: 'Community Health Clinic',
      address: '321 Community Dr',
      distance: 0.8,
      specialties: ['Family Medicine', 'General Practice'],
      rating: 4.4,
      isAvailable: true,
    ),
    Hospital(
      id: '5',
      name: 'Specialty Hospital',
      address: '654 Specialty Way',
      distance: 4.2,
      specialties: ['Cardiology', 'Neurology', 'Surgery'],
      rating: 4.7,
      isAvailable: true,
    ),
  ];

  // Initialize with mock data
  LocationController() {
    _nearbyHospitals = List.from(_mockHospitals);
    _recentHospitals = _mockHospitals.take(3).toList();
  }

  // Set selected hospital
  void setSelectedHospital(Hospital hospital) {
    _selectedHospital = hospital;
    
    // Add to recent hospitals if not already there
    if (!_recentHospitals.any((h) => h.id == hospital.id)) {
      _recentHospitals.insert(0, hospital);
      if (_recentHospitals.length > 5) {
        _recentHospitals.removeLast();
      }
    }
    
    notifyListeners();
  }

  // Set user location
  void setUserLocation(String location) {
    _userLocation = location;
    notifyListeners();
  }

  // Use my location (GPS simulation)
  Future<void> useMyLocation() async {
    _isLoading = true;
    notifyListeners();

    // Simulate GPS location fetch
    await Future.delayed(const Duration(seconds: 2));
    
    _userLocation = 'Current Location';
    _nearbyHospitals = List.from(_mockHospitals);
    
    // Sort by distance (simulate GPS-based sorting)
    _nearbyHospitals.sort((a, b) => a.distance.compareTo(b.distance));
    
    _isLoading = false;
    notifyListeners();
  }

  // Search hospitals
  List<Hospital> searchHospitals(String query) {
    if (query.isEmpty) return _nearbyHospitals;
    
    return _nearbyHospitals.where((hospital) {
      final searchQuery = query.toLowerCase();
      return hospital.name.toLowerCase().contains(searchQuery) ||
             hospital.address.toLowerCase().contains(searchQuery) ||
             hospital.specialties.any((specialty) => 
               specialty.toLowerCase().contains(searchQuery));
    }).toList();
  }

  // Clear selected hospital
  void clearSelectedHospital() {
    _selectedHospital = null;
    notifyListeners();
  }

  // Get hospital by ID
  Hospital? getHospitalById(String id) {
    try {
      return _nearbyHospitals.firstWhere((hospital) => hospital.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get hospitals by specialty
  List<Hospital> getHospitalsBySpecialty(String specialty) {
    return _nearbyHospitals.where((hospital) => 
      hospital.specialties.contains(specialty)).toList();
  }

  // Get context string for AI chat
  String getLocationContext() {
    if (_selectedHospital != null) {
      return 'Hospital: ${_selectedHospital!.name} (${_selectedHospital!.distance}km away)';
    } else if (_userLocation != null) {
      return 'Location: $_userLocation';
    }
    return 'No location selected';
  }
} 