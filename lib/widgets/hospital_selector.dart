import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../controllers/location_controller.dart';

class HospitalSelector extends StatelessWidget {
  final LocationController locationController;
  final VoidCallback? onTap;

  const HospitalSelector({
    super.key,
    required this.locationController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
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
          color: AppTheme.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Location Icon
          Container(
            width: isSmallScreen ? 24 : 28,
            height: isSmallScreen ? 24 : 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
            ),
            child: Icon(
              Icons.location_on,
              color: AppTheme.primaryColor,
              size: isSmallScreen ? 14 : 16,
            ),
          ),
          
          SizedBox(width: isSmallScreen ? 8 : 12),
          
          // Location Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Context',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: isSmallScreen ? 10 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  _getLocationText(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: isSmallScreen ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Change Button
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 10,
                vertical: isSmallScreen ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Change',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 9 : 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocationText() {
    if (locationController.selectedHospital != null) {
      final hospital = locationController.selectedHospital!;
      return '${hospital.name} (${hospital.distance}km)';
    } else if (locationController.userLocation != null) {
      return locationController.userLocation!;
    }
    return 'Select hospital or location';
  }
}

class HospitalSelectorModal extends StatefulWidget {
  final LocationController locationController;

  const HospitalSelectorModal({
    super.key,
    required this.locationController,
  });

  @override
  State<HospitalSelectorModal> createState() => _HospitalSelectorModalState();
}

class _HospitalSelectorModalState extends State<HospitalSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Hospital> _filteredHospitals = [];

  @override
  void initState() {
    super.initState();
    _filteredHospitals = widget.locationController.nearbyHospitals;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterHospitals(String query) {
    setState(() {
      _filteredHospitals = widget.locationController.searchHospitals(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Text(
                  'Select Hospital',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  iconSize: isSmallScreen ? 20 : 24,
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterHospitals,
              decoration: InputDecoration(
                hintText: 'Search hospitals...',
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
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.surfaceColor,
              ),
            ),
          ),
          
          // Use My Location Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await widget.locationController.useMyLocation();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.my_location),
                label: const Text('Use My Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          // Hospital List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
              itemCount: _filteredHospitals.length,
              itemBuilder: (context, index) {
                final hospital = _filteredHospitals[index];
                final isSelected = widget.locationController.selectedHospital?.id == hospital.id;
                
                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected ? BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ) : BorderSide.none,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      leading: Container(
                        width: isSmallScreen ? 40 : 48,
                        height: isSmallScreen ? 40 : 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
                        ),
                        child: Icon(
                          Icons.local_hospital,
                          color: AppTheme.primaryColor,
                          size: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      title: Text(
                        hospital.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Text(
                            hospital.address,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: isSmallScreen ? 12 : 14,
                                color: AppTheme.accentColor,
                              ),
                              SizedBox(width: isSmallScreen ? 2 : 4),
                              Text(
                                '${hospital.rating}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: isSmallScreen ? 10 : 11,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              Icon(
                                Icons.location_on,
                                size: isSmallScreen ? 12 : 14,
                                color: AppTheme.textLight,
                              ),
                              SizedBox(width: isSmallScreen ? 2 : 4),
                              Text(
                                '${hospital.distance}km',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textLight,
                                  fontSize: isSmallScreen ? 10 : 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: isSelected ? Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                        size: isSmallScreen ? 20 : 24,
                      ) : null,
                      onTap: () {
                        widget.locationController.setSelectedHospital(hospital);
                        Navigator.pop(context);
                      },
                    ),
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