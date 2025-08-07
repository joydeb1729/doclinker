import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../controllers/location_controller.dart';
import '../widgets/hospital_selector.dart';

class NearbyPage extends StatefulWidget {
  final LocationController locationController;

  const NearbyPage({
    super.key,
    required this.locationController,
  });

  @override
  State<NearbyPage> createState() => _NearbyPageState();
}

class _NearbyPageState extends State<NearbyPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Hospital> _filteredHospitals = [];
  String _selectedSpecialty = 'All';

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

  void _filterBySpecialty(String specialty) {
    setState(() {
      _selectedSpecialty = specialty;
      if (specialty == 'All') {
        _filteredHospitals = widget.locationController.nearbyHospitals;
      } else {
        _filteredHospitals = widget.locationController.getHospitalsBySpecialty(specialty);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Nearby Hospitals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            'Find hospitals and medical centers near you',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          // Use My Location Button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                Icon(
                  Icons.my_location,
                  color: AppTheme.primaryColor,
                  size: isSmallScreen ? 32 : 40,
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Text(
                  'Use My Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 8),
                Text(
                  'Find hospitals near your current location',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await widget.locationController.useMyLocation();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Location updated!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Get Nearby Hospitals'),
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
              ],
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          // Search Bar
          Container(
            decoration: AppTheme.cardDecoration,
            child: TextField(
              controller: _searchController,
              onChanged: _filterHospitals,
              decoration: InputDecoration(
                hintText: 'Search hospitals by name, address, or specialty...',
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
            ),
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          // Specialty Filter
          Text(
            'Filter by Specialty',
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
          
          SizedBox(height: isSmallScreen ? 16 : 24),
          
          // Hospital List
          Text(
            'Available Hospitals',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          
          // Hospital List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredHospitals.length,
            itemBuilder: (context, index) {
              final hospital = _filteredHospitals[index];
              final isSelected = widget.locationController.selectedHospital?.id == hospital.id;
              
              return Container(
                margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
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
                      width: isSmallScreen ? 48 : 56,
                      height: isSmallScreen ? 48 : 56,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                      ),
                      child: Icon(
                        Icons.local_hospital,
                        color: AppTheme.primaryColor,
                        size: isSmallScreen ? 24 : 28,
                      ),
                    ),
                    title: Text(
                      hospital.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 16 : 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: isSmallScreen ? 4 : 8),
                        Text(
                          hospital.address,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: isSmallScreen ? 11 : 12,
                          ),
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
                              '${hospital.rating}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                              '${hospital.distance}km away',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          children: hospital.specialties.take(3).map((specialty) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                                vertical: isSmallScreen ? 2 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                specialty,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontSize: isSmallScreen ? 9 : 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    trailing: isSelected ? Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: isSmallScreen ? 24 : 28,
                    ) : Icon(
                      Icons.arrow_forward_ios,
                      color: AppTheme.textLight,
                      size: isSmallScreen ? 16 : 18,
                    ),
                    onTap: () {
                      widget.locationController.setSelectedHospital(hospital);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected: ${hospital.name}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyChip(String specialty, bool isSmallScreen) {
    final isSelected = _selectedSpecialty == specialty;
    
    return GestureDetector(
      onTap: () => _filterBySpecialty(specialty),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 12,
          vertical: isSmallScreen ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textLight.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          specialty,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: isSmallScreen ? 10 : 11,
          ),
        ),
      ),
    );
  }
} 