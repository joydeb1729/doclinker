import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../controllers/location_controller.dart';
import '../models/doctor_profile.dart';

class DoctorSelector extends StatelessWidget {
  final LocationController locationController;
  final VoidCallback? onTap;

  const DoctorSelector({
    super.key,
    required this.locationController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 4 : 6,
      ),
      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap:
            onTap ??
            () {
              _showDoctorSelectorModal(context);
            },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 6 : 10,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: isSmallScreen ? 16 : 18,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: isSmallScreen ? 10 : 11,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      _getLocationText(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.textSecondary,
                size: isSmallScreen ? 18 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocationText() {
    if (locationController.selectedDoctor != null) {
      final doctor = locationController.selectedDoctor!;
      final distance = locationController.getDistanceToDoctor(doctor);
      return 'Dr. ${doctor.fullName} at ${doctor.hospitalAffiliation} '
          '(${distance != double.infinity ? "${distance.toStringAsFixed(1)}km" : "Distance unknown"})';
    } else if (locationController.userLocation != null) {
      return locationController.userLocation!.address;
    }
    return 'Select doctor or use current location';
  }

  void _showDoctorSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          DoctorSelectorModal(locationController: locationController),
    );
  }
}

class DoctorSelectorModal extends StatefulWidget {
  final LocationController locationController;

  const DoctorSelectorModal({super.key, required this.locationController});

  @override
  State<DoctorSelectorModal> createState() => _DoctorSelectorModalState();
}

class _DoctorSelectorModalState extends State<DoctorSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  List<DoctorProfile> _filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    _filteredDoctors = widget.locationController.nearbyDoctors;
    widget.locationController.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.locationController.removeListener(_onControllerChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {
        _filteredDoctors = widget.locationController.searchDoctors(
          _searchController.text,
        );
      });
    }
  }

  void _filterDoctors(String query) {
    setState(() {
      _filteredDoctors = widget.locationController.searchDoctors(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: AppTheme.textLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
            child: Row(
              children: [
                Text(
                  'Select Doctor or Location',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 18 : 20,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.textLight.withOpacity(0.1),
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Use My Location Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.locationController.isLoading
                    ? null
                    : () async {
                        await widget.locationController.useMyLocation();
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                icon: widget.locationController.isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  widget.locationController.isLoading
                      ? 'Getting Location...'
                      : 'Use My Current Location',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 16 : 20),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterDoctors,
              decoration: InputDecoration(
                hintText: 'Search doctors by name or hospital...',
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
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 12 : 16),

          // Doctors List
          Expanded(
            child: _filteredDoctors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: isSmallScreen ? 48 : 60,
                          color: AppTheme.textLight,
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Text(
                          'No doctors found',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          'Try a different search or get nearby doctors',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                    ),
                    itemCount: _filteredDoctors.length,
                    itemBuilder: (context, index) {
                      final doctor = _filteredDoctors[index];
                      final isSelected =
                          widget.locationController.selectedDoctor?.uid ==
                          doctor.uid;
                      final distance = widget.locationController
                          .getDistanceToDoctor(doctor);

                      return Container(
                        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(
                            isSmallScreen ? 12 : 16,
                          ),
                          tileColor: isSelected
                              ? AppTheme.primaryColor.withOpacity(0.1)
                              : AppTheme.surfaceColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isSelected
                                ? BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                          leading: Container(
                            width: isSmallScreen ? 40 : 48,
                            height: isSmallScreen ? 40 : 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                isSmallScreen ? 20 : 24,
                              ),
                            ),
                            child: Icon(
                              Icons.local_hospital,
                              color: AppTheme.primaryColor,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          title: Text(
                            'Dr. ${doctor.fullName}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: isSmallScreen ? 2 : 4),
                              Text(
                                doctor.hospitalAffiliation,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: isSmallScreen ? 11 : 12,
                                    ),
                              ),
                              SizedBox(height: isSmallScreen ? 2 : 4),
                              Text(
                                distance != double.infinity
                                    ? '${distance.toStringAsFixed(1)}km away'
                                    : 'Distance unknown',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textLight,
                                      fontSize: isSmallScreen ? 10 : 11,
                                    ),
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryColor,
                                  size: isSmallScreen ? 20 : 24,
                                )
                              : null,
                          onTap: () {
                            widget.locationController.setSelectedDoctor(doctor);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
