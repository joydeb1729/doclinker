import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../app_theme.dart';
import '../controllers/location_controller.dart';
import '../models/doctor_profile.dart';
import '../models/hospital_profile.dart';

class LocationMapWidget extends StatefulWidget {
  final LocationController locationController;
  final double height;
  final bool showDoctors;

  const LocationMapWidget({
    super.key,
    required this.locationController,
    this.height = 200,
    this.showDoctors = true,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _lastKnownCenter;

  @override
  void initState() {
    super.initState();
    widget.locationController.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    widget.locationController.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    if (!mounted) return;

    final userLocation = widget.locationController.userLocation;
    if (userLocation != null) {
      final newCenter = LatLng(userLocation.latitude, userLocation.longitude);

      // Only move map if location actually changed significantly (>100m)
      if (_lastKnownCenter == null ||
          _calculateDistance(_lastKnownCenter!, newCenter) > 0.1) {
        print(
          'LocationMapWidget: Moving map to new location: ${newCenter.latitude}, ${newCenter.longitude}',
        );

        _lastKnownCenter = newCenter;

        // Use Future.delayed to ensure map controller is ready
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _mapController.move(newCenter, 14.0);
          }
        });
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    double dLat = _toRadians(point2.latitude - point1.latitude);
    double dLng = _toRadians(point2.longitude - point1.longitude);
    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(point1.latitude)) *
            math.cos(_toRadians(point2.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    final userLocation = widget.locationController.userLocation;

    // Default to Khulna if no user location
    final center = userLocation != null
        ? LatLng(userLocation.latitude, userLocation.longitude)
        : LatLng(22.8456, 89.5403); // Khulna, Bangladesh

    // Set initial center if this is the first time
    _lastKnownCenter ??= center;

    print(
      'LocationMapWidget: Building with location: ${userLocation?.address} at ${center.latitude}, ${center.longitude}',
    );

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: userLocation != null ? 14.0 : 11.0,
                minZoom: 8.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.doclinker.app',
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),

            // Location status indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IntrinsicWidth(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        userLocation != null
                            ? Icons.location_on
                            : Icons.location_off,
                        size: 14,
                        color: userLocation != null
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          userLocation?.address ?? 'No GPS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: userLocation != null
                                ? AppTheme.primaryColor
                                : Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // User location marker (blue)
    if (widget.locationController.userLocation != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.locationController.userLocation!.latitude,
            widget.locationController.userLocation!.longitude,
          ),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.person_pin, color: Colors.white, size: 18),
          ),
        ),
      );
    }

    // Doctor markers (green color)
    if (widget.showDoctors &&
        (widget.locationController.searchMode == 'doctors' ||
            widget.locationController.searchMode == 'both')) {
      for (DoctorProfile doctor in widget.locationController.nearbyDoctors.take(
        10,
      )) {
        // Skip doctors without valid coordinates
        if (doctor.latitude == null || doctor.longitude == null) continue;

        markers.add(
          Marker(
            point: LatLng(doctor.latitude!, doctor.longitude!),
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: () => widget.locationController.setSelectedDoctor(doctor),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      widget.locationController.selectedDoctor?.uid ==
                          doctor.uid
                      ? Colors.orange
                      : AppTheme.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 16),
              ),
            ),
          ),
        );
      }
    }

    // Hospital markers (red color)
    if (widget.showDoctors &&
        (widget.locationController.searchMode == 'hospitals' ||
            widget.locationController.searchMode == 'both')) {
      for (HospitalProfile hospital
          in widget.locationController.nearbyHospitals.take(10)) {
        // Skip hospitals without valid coordinates
        if (hospital.latitude == null || hospital.longitude == null) continue;

        markers.add(
          Marker(
            point: LatLng(hospital.latitude!, hospital.longitude!),
            width: 32,
            height: 32,
            child: GestureDetector(
              onTap: () =>
                  widget.locationController.setSelectedHospital(hospital),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      widget.locationController.selectedHospital?.uid ==
                          hospital.uid
                      ? Colors.orange
                      : Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }
}
