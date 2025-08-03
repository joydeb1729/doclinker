import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_theme.dart';
import 'home_screen.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();

  bool _isLoading = false;
  String? _selectedGender;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  // Phone validation
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // Age validation
  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 120) {
      return 'Please enter a valid age';
    }
    return null;
  }

  // Complete profile setup
  Future<void> _completeProfileSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Here you would typically save additional user data to Firestore
      // For now, we'll just simulate a delay and navigate to home
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile setup completed!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile setup failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skipProfileSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _skipProfileSetup,
            child: Text(
              'Skip',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and title
                  Container(
                    width: 100,
                    height: 100,
                    decoration: AppTheme.gradientDecoration,
                    child: const Icon(
                      Icons.handshake,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Complete Your Profile',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Help us personalize your experience',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Phone field
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Age field
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      hintText: 'Enter your age',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validateAge,
                    enabled: !_isLoading,
                  ),

                  const SizedBox(height: 16),

                  // Gender dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      hintText: 'Select your gender',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: _genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Complete profile button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _completeProfileSetup,
                      child: _isLoading
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
                          : const Text('Complete Profile'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Skip for now button
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _skipProfileSetup,
                      child: const Text('Skip for now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
