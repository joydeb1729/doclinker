import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../controllers/location_controller.dart';
import '../models/hospital_profile.dart';
import '../services/location_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/location_map_widget.dart';

class NearbyPage extends StatefulWidget {
  final LocationController locationController;

  const NearbyPage({super.key, required this.locationController});

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  final TextEditingController _searchController = TextEditingController();
  List<HospitalProfile> _filteredHospitals = [];
  double _searchRadius = 5.0; // Default 5km radius
  HospitalProfile? _selectedHospital;
  bool _isLocationSet = false;

  @override
  void initState() {
    super.initState();
    // Set search mode to hospitals only
    widget.locationController.setSearchMode('hospitals');
    _filteredHospitals = List.from(widget.locationController.nearbyHospitals);

    // Listen to location controller changes
    widget.locationController.addListener(_onLocationControllerChanged);

    // Check if location is already set
    _isLocationSet = widget.locationController.userLocation != null;

    // Auto-load location on init if not already loaded
    if (widget.locationController.userLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.locationController.useMyLocation();
      });
    }
  }

  @override
  void dispose() {
    widget.locationController.removeListener(_onLocationControllerChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onLocationControllerChanged() {
    if (mounted) {
      setState(() {
        _filteredHospitals = List.from(
          widget.locationController.nearbyHospitals,
        );
        _isLocationSet = widget.locationController.userLocation != null;
        _selectedHospital = widget.locationController.selectedHospital;
        _filterHospitals();
      });
    }
  }

  void _filterByService(String service) {
    widget.locationController.setSelectedSpecialty(service);
    if (_isLocationSet) {
      _searchHospitalsWithService(service);
    }
  }

  Future<void> _searchHospitalsWithService(String service) async {
    if (widget.locationController.userLocation == null) return;

    try {
      final hospitals = await LocationService.getNearbyHospitals(
        widget.locationController.userLocation!.latitude,
        widget.locationController.userLocation!.longitude,
        radiusInKm: _searchRadius,
        serviceFilter: service == 'All' ? null : service,
      );

      setState(() {
        widget.locationController.nearbyHospitals.clear();
        widget.locationController.nearbyHospitals.addAll(hospitals);
        _filteredHospitals = List.from(hospitals);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error filtering hospitals: $e')));
    }
  }

  void _filterHospitals() {
    String query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredHospitals = List.from(
          widget.locationController.nearbyHospitals,
        );
      } else {
        _filteredHospitals = widget.locationController.nearbyHospitals.where((
          hospital,
        ) {
          return hospital.name.toLowerCase().contains(query) ||
              hospital.address.toLowerCase().contains(query) ||
              hospital.type.toLowerCase().contains(query) ||
              hospital.services.any(
                (service) => service.toLowerCase().contains(query),
              );
        }).toList();
      }
    });
  }

  void _updateSearchRadius(double radius) {
    print(
      '🎚️  Radius slider changed: ${_searchRadius}km → ${radius}km (not searching yet)',
    );
    setState(() {
      _searchRadius = radius;
    });
    // No automatic search - user must click refresh button
  }

  Future<void> _searchHospitalsWithRadius() async {
    if (widget.locationController.userLocation == null) return;

    print('🔍 Starting hospital search with ${_searchRadius}km radius...');
    try {
      final hospitals = await LocationService.getNearbyHospitals(
        widget.locationController.userLocation!.latitude,
        widget.locationController.userLocation!.longitude,
        radiusInKm: _searchRadius,
      );

      print('✅ Main search completed: ${hospitals.length} hospitals found');
      setState(() {
        widget.locationController.nearbyHospitals.clear();
        widget.locationController.nearbyHospitals.addAll(hospitals);
        _filteredHospitals = List.from(hospitals);
      });
      print('🔄 UI updated with ${_filteredHospitals.length} hospitals');
    } catch (e) {
      print('❌ Error in main hospital search: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching hospitals: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with location info
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                Icon(
                  Icons.location_searching,
                  size: isSmallScreen ? 32 : 40,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  'Select Hospital Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isSmallScreen ? 18 : 22,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 8),
                Text(
                  'Choose a hospital location to find doctors',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),

                // Interactive Map
                if (widget.locationController.userLocation != null) ...[
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Column(
                    children: [
                      LocationMapWidget(
                        locationController: widget.locationController,
                        height: isSmallScreen ? 120 : 150,
                        showDoctors: true,
                      ),
                      if (widget
                          .locationController
                          .nearbyDoctors
                          .isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          'Tap doctor markers to select • ${widget.locationController.nearbyDoctors.length} doctors shown',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textLight,
                                fontSize: isSmallScreen ? 9 : 10,
                                fontStyle: FontStyle.italic,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: isSmallScreen ? 12 : 14,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Flexible(
                          child: Text(
                            widget.locationController.userLocation!.address,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontSize: isSmallScreen ? 9 : 10,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.locationController.isLoading
                        ? null
                        : () async {
                            print('UI: Location button pressed');
                            await widget.locationController.useMyLocation();
                          },
                    icon: widget.locationController.isLoading
                        ? SizedBox(
                            width: isSmallScreen ? 16 : 20,
                            height: isSmallScreen ? 16 : 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            widget.locationController.userLocation != null
                                ? Icons.refresh
                                : Icons.my_location,
                          ),
                    label: Text(
                      widget.locationController.isLoading
                          ? 'Getting Location...'
                          : widget.locationController.userLocation != null
                          ? 'Update Location & Doctors'
                          : 'Get My Location',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // Error message with action buttons
                if (widget.locationController.errorMessage != null) ...[
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning,
                              size: isSmallScreen ? 16 : 18,
                              color: Colors.red,
                            ),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Expanded(
                              child: Text(
                                widget.locationController.errorMessage!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.red,
                                      fontSize: isSmallScreen ? 11 : 12,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                widget.locationController.clearError();
                              },
                              icon: Icon(
                                Icons.close,
                                size: isSmallScreen ? 16 : 18,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Wrap(
                          spacing: isSmallScreen ? 4 : 8,
                          runSpacing: isSmallScreen ? 4 : 6,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                await widget.locationController
                                    .openLocationSettings();
                              },
                              icon: Icon(
                                Icons.settings,
                                size: isSmallScreen ? 12 : 14,
                              ),
                              label: Text(
                                'Settings',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9 : 10,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 6 : 8,
                                  vertical: isSmallScreen ? 2 : 4,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () async {
                                await widget.locationController.useMyLocation();
                              },
                              icon: Icon(
                                Icons.refresh,
                                size: isSmallScreen ? 12 : 14,
                              ),
                              label: Text(
                                'Try Again',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9 : 10,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 6 : 8,
                                  vertical: isSmallScreen ? 2 : 4,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _showLocationSelector(context);
                              },
                              icon: Icon(
                                Icons.location_city,
                                size: isSmallScreen ? 12 : 14,
                              ),
                              label: Text(
                                'Set Khulna',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9 : 10,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primaryColor,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 6 : 8,
                                  vertical: isSmallScreen ? 2 : 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Search Bar
          Container(
            decoration: AppTheme.cardDecoration,
            child: TextField(
              controller: _searchController,
              onChanged: (query) => _filterHospitals(),
              decoration: InputDecoration(
                hintText: 'Search hospitals by name, type, or service...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.textLight.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.textLight.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor),
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 8 : 12),

          // Search Mode Selector
          Text(
            'What are you looking for?',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Select Hospital for Doctor Search',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Search Radius Slider
          Row(
            children: [
              Text(
                'Search Radius: ${_searchRadius.toInt()} km',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(Click refresh to apply)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: isSmallScreen ? 10 : 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Slider(
            value: _searchRadius,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            label: '${_searchRadius.toInt()} km',
            onChanged: _updateSearchRadius,
            activeColor: AppTheme.primaryColor,
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Service Filter
          Text(
            'Filter by Service',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: widget.locationController.searchMode == 'hospitals'
                  ? [
                      _buildSpecialtyChip('All', isSmallScreen),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      _buildSpecialtyChip('emergency', isSmallScreen),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      _buildSpecialtyChip('icu', isSmallScreen),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      _buildSpecialtyChip('24hours', isSmallScreen),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      _buildSpecialtyChip('ambulance', isSmallScreen),
                    ]
                  : [
                      _buildSpecialtyChip('All', isSmallScreen),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      _buildSpecialtyChip('Cardiology', isSmallScreen),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      _buildSpecialtyChip('Neurology', isSmallScreen),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      _buildSpecialtyChip('Dermatology', isSmallScreen),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      _buildSpecialtyChip('Orthopedics', isSmallScreen),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      _buildSpecialtyChip('General Medicine', isSmallScreen),
                    ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Hospital List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Available Hospitals (${_filteredHospitals.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.locationController.isLoading &&
                  widget.locationController.userLocation != null)
                TextButton.icon(
                  onPressed: () {
                    print(
                      '🔄 Refresh button pressed - using current radius: ${_searchRadius}km',
                    );
                    _searchHospitalsWithRadius(); // Single refresh button
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),

          // Doctors List
          widget.locationController.isLoading
              ? Container(
                  height: 100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: isSmallScreen ? 20 : 24,
                          height: isSmallScreen ? 20 : 24,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        Text(
                          'Loading...',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontSize: isSmallScreen ? 10 : 12),
                        ),
                      ],
                    ),
                  ),
                )
              : _filteredHospitals.isEmpty
              ? Container(
                  height: 120,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: isSmallScreen ? 48 : 64,
                          color: AppTheme.textLight,
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Text(
                          'No doctors found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: isSmallScreen ? 14 : 16,
                              ),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          'Try adjusting your search or location',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.textLight,
                                fontSize: isSmallScreen ? 10 : 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredHospitals.length,
                  itemBuilder: (context, index) {
                    final hospital = _filteredHospitals[index];
                    final isSelected =
                        widget.locationController.selectedHospital?.uid ==
                        hospital.uid;
                    final distance = LocationService.getDistanceToHospital(
                      widget.locationController.userLocation!.latitude,
                      widget.locationController.userLocation!.longitude,
                      hospital,
                    );

                    return Container(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelected
                              ? BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(
                            isSmallScreen ? 12 : 16,
                          ),
                          leading: Container(
                            width: isSmallScreen ? 48 : 56,
                            height: isSmallScreen ? 48 : 56,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                isSmallScreen ? 24 : 28,
                              ),
                            ),
                            child: Icon(
                              Icons.local_hospital,
                              color: AppTheme.primaryColor,
                              size: isSmallScreen ? 24 : 28,
                            ),
                          ),
                          title: Text(
                            hospital.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 16 : 18,
                                ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: isSmallScreen ? 4 : 8),
                              Row(
                                children: [
                                  Icon(
                                    hospital.isGovernment
                                        ? Icons.account_balance
                                        : Icons.business,
                                    size: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${hospital.type} • ${hospital.isGovernment ? "Government" : "Private"}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                            fontSize: isSmallScreen ? 11 : 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 2 : 4),
                              Text(
                                hospital.address,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: isSmallScreen ? 10 : 11,
                                    ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: isSmallScreen ? 14 : 16,
                                    color: AppTheme.accentColor,
                                  ),
                                  SizedBox(width: isSmallScreen ? 4 : 6),
                                  Text(
                                    hospital.rating > 0
                                        ? '${hospital.rating.toStringAsFixed(1)}'
                                        : 'N/A',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: isSmallScreen ? 11 : 12,
                                        ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 12 : 16),
                                  Icon(
                                    Icons.location_on,
                                    size: isSmallScreen ? 14 : 16,
                                    color: AppTheme.textLight,
                                  ),
                                  SizedBox(width: isSmallScreen ? 4 : 6),
                                  Text(
                                    distance != double.infinity
                                        ? '${distance.toStringAsFixed(1)}km away'
                                        : 'Distance unknown',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textLight,
                                          fontSize: isSmallScreen ? 11 : 12,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 8),
                              Wrap(
                                spacing: isSmallScreen ? 4 : 6,
                                runSpacing: isSmallScreen ? 2 : 4,
                                children: hospital.services.take(4).map((
                                  service,
                                ) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 6 : 8,
                                      vertical: isSmallScreen ? 2 : 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      service,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontSize: isSmallScreen ? 9 : 10,
                                          ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: isSmallScreen ? 4 : 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (hospital.hasEmergency) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.emergency,
                                          size: 14,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Emergency',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (hospital.is24Hours) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '24 Hours',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    Text(
                                      hospital.getDisplayOperatingHours(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                            fontSize: isSmallScreen ? 10 : 11,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryColor,
                                  size: isSmallScreen ? 24 : 28,
                                )
                              : Icon(
                                  Icons.arrow_forward_ios,
                                  color: AppTheme.textLight,
                                  size: isSmallScreen ? 16 : 18,
                                ),
                          onTap: () {
                            setState(() {
                              _selectedHospital = hospital;
                            });
                            widget.locationController.setSelectedHospital(
                              hospital,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Selected: ${hospital.name}'),
                                  duration: const Duration(seconds: 2),
                                  action: SnackBarAction(
                                    label: 'Find Doctors',
                                    onPressed: () {
                                      Navigator.pop(context, hospital);
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
          // Selected Hospital Action Bar
          if (_selectedHospital != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_hospital,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Selected Hospital',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedHospital!.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedHospital!.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Return selected hospital to previous page
                        Navigator.pop(context, _selectedHospital);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 20),
                      label: Text(
                        'Find Doctors at This Hospital',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialtyChip(String specialty, bool isSmallScreen) {
    final isSelected = widget.locationController.selectedSpecialty == specialty;

    // Display names for hospital services
    String displayName = specialty;
    if (widget.locationController.searchMode == 'hospitals') {
      switch (specialty.toLowerCase()) {
        case 'emergency':
          displayName = 'Emergency';
          break;
        case 'icu':
          displayName = 'ICU';
          break;
        case '24hours':
          displayName = '24 Hours';
          break;
        case 'ambulance':
          displayName = 'Ambulance';
          break;
        default:
          displayName = specialty;
      }
    }

    return GestureDetector(
      onTap: () => _filterByService(specialty),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 12,
          vertical: isSmallScreen ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textLight.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          displayName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: isSmallScreen ? 10 : 11,
          ),
        ),
      ),
    );
  }

  void _showLocationSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Your Location',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.location_city, color: Colors.blue),
              title: const Text('Khulna, Bangladesh'),
              subtitle: const Text('22.8486°N, 89.5403°E'),
              onTap: () {
                widget.locationController.setUserLocation(
                  const LocationResult(
                    latitude: 22.8456,
                    longitude: 89.5403,
                    address: 'Khulna, Bangladesh',
                  ),
                );
                widget.locationController.refreshNearbyDoctors();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_city, color: Colors.green),
              title: const Text('Dhaka, Bangladesh'),
              subtitle: const Text('23.8103°N, 90.4125°E'),
              onTap: () {
                widget.locationController.setUserLocation(
                  const LocationResult(
                    latitude: 23.8103,
                    longitude: 90.4125,
                    address: 'Dhaka, Bangladesh',
                  ),
                );
                widget.locationController.refreshNearbyDoctors();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_city, color: Colors.orange),
              title: const Text('Chittagong, Bangladesh'),
              subtitle: const Text('22.3569°N, 91.7832°E'),
              onTap: () {
                widget.locationController.setUserLocation(
                  const LocationResult(
                    latitude: 22.3569,
                    longitude: 91.7832,
                    address: 'Chittagong, Bangladesh',
                  ),
                );
                widget.locationController.refreshNearbyDoctors();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
