import 'package:flutter_test/flutter_test.dart';
import 'package:doclinker/services/location_service.dart';
import 'package:doclinker/controllers/location_controller.dart';

void main() {
  group('Location Services Tests', () {
    late LocationController locationController;

    setUp(() {
      locationController = LocationController();
    });

    test('LocationController initializes correctly', () {
      expect(locationController, isNotNull);
      expect(locationController.nearbyDoctors, isEmpty);
      expect(locationController.selectedDoctor, isNull);
      expect(locationController.userLocation, isNull);
      expect(locationController.isLoading, false);
    });

    test('LocationService calculateDistance works correctly', () {
      // Test distance calculation between two known points
      // Dhaka to Chittagong approximate coordinates
      double distance = LocationService.calculateDistance(
        23.8103,
        90.4125, // Dhaka
        22.3569,
        91.7832, // Chittagong
      );

      // Should be approximately 242 km
      expect(distance, greaterThan(240));
      expect(distance, lessThan(250));
    });

    test('LocationService getMockLocation returns valid location', () {
      LocationResult mockLocation = LocationService.getMockLocation();

      expect(mockLocation, isNotNull);
      expect(mockLocation.latitude, 23.8103);
      expect(mockLocation.longitude, 90.4125);
      expect(mockLocation.address, 'Dhaka, Bangladesh');
    });

    test('LocationController handles specialty filtering', () {
      // Test that specialty filtering updates correctly
      String initialSpecialty = locationController.selectedSpecialty;
      expect(initialSpecialty, 'All');

      locationController.setSelectedSpecialty('Cardiology');
      expect(locationController.selectedSpecialty, 'Cardiology');
    });
  });
}
