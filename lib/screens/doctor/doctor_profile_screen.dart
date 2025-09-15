import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../models/doctor_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/navigation_service.dart';

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
  final _hospitalController = TextEditingController();
  final _degreeController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _addressController = TextEditingController();
  final _clinicPhoneController = TextEditingController();

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

  void _populateFields(DoctorProfile profile) {
    _nameController.text = profile.fullName;
    _phoneController.text = profile.phoneNumber ?? '';
    _licenseController.text = profile.medicalLicense;
    _hospitalController.text = profile.hospitalAffiliation;
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
                hospitalAffiliation: _hospitalController.text.trim(),
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

      final doctorService = DoctorService();
      await doctorService.saveDoctorProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
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
        TextFormField(
          controller: _hospitalController,
          decoration: const InputDecoration(
            labelText: 'Hospital/Clinic Affiliation*',
            prefixIcon: Icon(Icons.local_hospital_outlined),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Hospital affiliation is required';
            }
            return null;
          },
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
