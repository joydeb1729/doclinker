import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../models/doctor_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/navigation_service.dart';
import '../../services/profile_validation_service.dart';
import '../../services/embedding_service.dart';
import '../../constants/hospital_constants.dart';

class DoctorProfileScreen extends ConsumerStatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  ConsumerState<DoctorProfileScreen> createState() =>
      _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends ConsumerState<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _hospitalController =
      TextEditingController(); // Keep for backward compatibility
  final _degreeController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _addressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();

  // Hospital dropdown state
  String? _selectedHospital;

  DoctorProfile? _doctorProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  List<String> _selectedSpecializations = [];
  List<String> _certifications = [];
  Map<String, List<String>> _weeklyAvailability = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };
  bool _isEmergencyAvailable = false;

  final List<String> _availableSpecializations = [
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'Psychiatry',
    'Gynecology',
    'Ophthalmology',
    'ENT',
    'Gastroenterology',
    'Pulmonology',
    'Endocrinology',
    'Rheumatology',
    'Oncology',
    'Nephrology',
    'Anesthesiology',
    'Radiology',
    'Pathology',
    'Emergency Medicine',
  ];

  final List<String> _timeSlots = [
    '08:00 - 09:00',
    '09:00 - 10:00',
    '10:00 - 11:00',
    '11:00 - 12:00',
    '12:00 - 13:00',
    '13:00 - 14:00',
    '14:00 - 15:00',
    '15:00 - 16:00',
    '16:00 - 17:00',
    '17:00 - 18:00',
    '18:00 - 19:00',
    '19:00 - 20:00',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctorProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _hospitalController.dispose();
    _degreeController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _addressController.dispose();
    _clinicPhoneController.dispose();

    super.dispose();
  }

  Future<void> _loadDoctorProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doctorService = DoctorService();
        final profile = await doctorService.getDoctorProfile(user.uid);

        if (profile != null) {
          _doctorProfile = profile;
          _populateFields(profile);
        }

        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        print('Error loading doctor profile: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Find the best matching hospital from our predefined list
  String? _findMatchingHospital(String originalHospital) {
    if (originalHospital.isEmpty) return null;

    // First, check for exact match
    if (HospitalConstants.bangladeshHospitals.contains(originalHospital)) {
      return originalHospital;
    }

    // Normalize both strings for comparison
    final lowerOriginal = originalHospital.toLowerCase().trim();

    // Look for the best match using more precise criteria
    String? bestMatch;
    int highestScore = 0;

    for (String hospital in HospitalConstants.bangladeshHospitals) {
      final lowerHospital = hospital.toLowerCase().trim();
      int score = 0;

      // Calculate similarity score based on multiple factors

      // 1. Check for high similarity in core hospital name (before comma)
      final originalCore = lowerOriginal.split(',')[0].trim();
      final hospitalCore = lowerHospital.split(',')[0].trim();

      // 2. Handle common typos and variations
      String normalizedOriginal = originalCore
          .replaceAll('collage', 'college') // Fix common typo
          .replaceAll('  ', ' ') // Remove double spaces
          .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace

      String normalizedHospital = hospitalCore
          .replaceAll('  ', ' ')
          .replaceAll(RegExp(r'\s+'), ' ');

      // 3. Check for exact match after normalization
      if (normalizedOriginal == normalizedHospital) {
        score = 100; // Perfect match
      }
      // 4. Check if one is contained in the other (high confidence)
      else if (normalizedHospital.contains(normalizedOriginal) ||
          normalizedOriginal.contains(normalizedHospital)) {
        score = 80;
      }
      // 5. Check for substantial word overlap
      else {
        final originalWords = normalizedOriginal
            .split(' ')
            .where((w) => w.length > 2)
            .toSet();
        final hospitalWords = normalizedHospital
            .split(' ')
            .where((w) => w.length > 2)
            .toSet();
        final intersection = originalWords.intersection(hospitalWords);

        if (intersection.length >= 2 &&
            intersection.length >= originalWords.length * 0.6) {
          score = 60;
        }
      }

      // Update best match if this score is higher
      if (score > highestScore && score >= 60) {
        // Minimum threshold of 60
        highestScore = score;
        bestMatch = hospital;
      }
    }

    return bestMatch;
  }

  void _populateFields(DoctorProfile profile) {
    _nameController.text = profile.fullName;
    _phoneController.text = profile.phoneNumber ?? '';
    _licenseController.text = profile.medicalLicense;

    // Handle hospital affiliation - validate against our predefined list
    if (profile.hospitalAffiliation.isNotEmpty) {
      _selectedHospital = _findMatchingHospital(profile.hospitalAffiliation);

      // Log if we had to do fallback matching
      if (_selectedHospital != profile.hospitalAffiliation) {
        print(
          '🏥 Hospital mapping: "${profile.hospitalAffiliation}" -> "$_selectedHospital"',
        );
      }
    }

    _degreeController.text = profile.medicalDegree;
    _experienceController.text = profile.yearsOfExperience.toString();
    _feeController.text = profile.consultationFee.toString();
    _addressController.text = profile.clinicAddress;
    _clinicPhoneController.text = profile.clinicPhone ?? '';

    _selectedSpecializations = List.from(profile.specializations);
    _certifications = List.from(profile.certifications);
    _weeklyAvailability = Map.from(profile.weeklyAvailability);
    _isEmergencyAvailable = profile.isAvailableForEmergency;

    // Debug: Print weekly availability data
    print('Loaded weekly availability: $_weeklyAvailability');
    print('Available specializations: $_selectedSpecializations');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updatedProfile =
          (_doctorProfile ??
                  DoctorProfile(
                    uid: user.uid,
                    email: user.email ?? '',
                    fullName: '',
                    medicalLicense: '',
                    specializations: [],
                    hospitalAffiliation: '',
                    yearsOfExperience: 0,
                    medicalDegree: '',
                    clinicAddress: '',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ))
              .copyWith(
                fullName: _nameController.text.trim(),
                phoneNumber: _phoneController.text.trim().isEmpty
                    ? null
                    : _phoneController.text.trim(),
                medicalLicense: _licenseController.text.trim(),
                hospitalAffiliation: _selectedHospital ?? '',
                medicalDegree: _degreeController.text.trim(),
                yearsOfExperience:
                    int.tryParse(_experienceController.text) ?? 0,
                consultationFee: double.tryParse(_feeController.text) ?? 0.0,
                clinicAddress: _addressController.text.trim(),
                clinicPhone: _clinicPhoneController.text.trim().isEmpty
                    ? null
                    : _clinicPhoneController.text.trim(),
                specializations: _selectedSpecializations,
                certifications: _certifications,
                weeklyAvailability: _weeklyAvailability,
                isAvailableForEmergency: _isEmergencyAvailable,
                updatedAt: DateTime.now(),
              );

      // Generate new embedding for the updated profile
      final embedding = await EmbeddingService.generateDoctorEmbedding(
        updatedProfile,
      );
      final profileWithEmbedding = updatedProfile.copyWith(
        profileEmbedding: embedding,
      );

      final doctorService = DoctorService();
      await doctorService.saveDoctorProfile(profileWithEmbedding);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully with new embedding'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NavigationService.navigateToLogin(context);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('Doctor Profile'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final auth = ref.read(authProvider);
                  await auth.signOut();
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_doctorProfile != null)
                          _buildProfileCompletenessCard(),
                        if (_doctorProfile != null) const SizedBox(height: 24),
                        _buildBasicInfoSection(),
                        const SizedBox(height: 24),
                        _buildMedicalInfoSection(),
                        const SizedBox(height: 24),
                        _buildSpecializationsSection(),
                        const SizedBox(height: 24),
                        _buildAvailabilitySection(),
                        const SizedBox(height: 24),
                        _buildContactSection(),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Save Profile'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCompletenessCard() {
    if (_doctorProfile == null) return const SizedBox.shrink();

    final completionPercentage = _doctorProfile!.profileCompletionPercentage;
    final isComplete = _doctorProfile!.isProfileComplete;
    final validationMessage = ProfileValidationService.getValidationMessage(
      _doctorProfile!,
    );
    final canAcceptAppointments =
        ProfileValidationService.canAcceptAppointments(_doctorProfile!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isComplete ? Icons.check_circle : Icons.info_outline,
                  color: isComplete ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Profile Completion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${completionPercentage.toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              validationMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            if (!canAcceptAppointments) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete your profile to start accepting appointments',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Basic Information',
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name*',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Full name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildMedicalInfoSection() {
    return _buildSection(
      title: 'Medical Information',
      children: [
        TextFormField(
          controller: _licenseController,
          decoration: const InputDecoration(
            labelText: 'Medical License*',
            prefixIcon: Icon(Icons.badge_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Medical license is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _degreeController,
          decoration: const InputDecoration(
            labelText: 'Medical Degree*',
            prefixIcon: Icon(Icons.school_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Medical degree is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // Hospital Dropdown with Search
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hospital/Clinic Affiliation*',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                value: _selectedHospital,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintText: 'Select Hospital/Clinic',
                ),
                isExpanded: true,
                items: HospitalConstants.bangladeshHospitals.map((
                  String hospital,
                ) {
                  return DropdownMenuItem<String>(
                    value: hospital,
                    child: Text(
                      hospital,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedHospital = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Hospital affiliation is required';
                  }
                  return null;
                },
                dropdownColor: Colors.white,
                iconSize: 24,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _experienceController,
          decoration: const InputDecoration(
            labelText: 'Years of Experience*',
            prefixIcon: Icon(Icons.work_outline),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Experience is required';
            }
            final experience = int.tryParse(value);
            if (experience == null || experience < 0) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _feeController,
          decoration: const InputDecoration(
            labelText: 'Consultation Fee (\৳)',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                '৳', // Unicode Taka symbol
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildSpecializationsSection() {
    return _buildSection(
      title: 'Specializations',
      children: [
        const Text('Select your specializations:'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSpecializations.map((specialization) {
            final isSelected = _selectedSpecializations.contains(
              specialization,
            );
            return FilterChip(
              label: Text(
                specialization,
                style: const TextStyle(
                  color: Colors.black, // ✅ unselected text is black
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSpecializations.add(specialization);
                  } else {
                    _selectedSpecializations.remove(specialization);
                  }
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? AppTheme
                          .primaryColor // ✅ selected text color
                    : Colors.black, // ✅ unselected text color
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return _buildSection(
      title: 'Availability',
      children: [
        SwitchListTile(
          title: const Text('Available for Emergency'),
          subtitle: const Text('Can handle emergency cases'),
          value: _isEmergencyAvailable,
          onChanged: (value) {
            setState(() {
              _isEmergencyAvailable = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Schedule:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your available time slots for each day:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Text(
                'Total time slots available: ${_timeSlots.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Show all 7 days of the week
              ...[
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ].map((day) {
                return _buildDayAvailability(
                  day,
                  _weeklyAvailability[day] ?? [],
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayAvailability(String day, List<String> timeSlots) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              day,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black, // ✅ ensure day name is black
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Available time slots: ${_timeSlots.length}',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final isSelected = timeSlots.contains(slot);
                return FilterChip(
                  label: Text(
                    slot,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black, // ✅ unselected stays black
                    ),
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? AppTheme
                              .primaryColor // ✅ selected text
                        : Colors.black, // ✅ unselected text
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      // Ensure the list exists for this day
                      _weeklyAvailability[day] ??= [];

                      if (selected) {
                        _weeklyAvailability[day]!.add(slot);
                      } else {
                        _weeklyAvailability[day]!.remove(slot);
                      }
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  checkmarkColor: AppTheme.primaryColor,
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
            if (timeSlots.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'No time slots selected for this day - Click any slot above to select',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (timeSlots.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: ${timeSlots.length} slots',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return _buildSection(
      title: 'Contact & Location',
      children: [
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Clinic Address*',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Clinic address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _clinicPhoneController,
          decoration: const InputDecoration(
            labelText: 'Clinic Phone',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
