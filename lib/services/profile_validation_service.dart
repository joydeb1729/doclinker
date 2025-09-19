import '../models/doctor_profile.dart';

class ProfileValidationService {
  static const List<String> criticalFields = [
    'Medical License',
    'Medical Degree',
    'At least one specialization',
  ];

  // Check if profile meets minimum requirements to accept appointments
  static bool canAcceptAppointments(DoctorProfile profile) {
    return profile.isProfileComplete;
  }

  // Check if profile meets requirements to be publicly searchable
  static bool canBeSearchable(DoctorProfile profile) {
    final completionPercentage = profile.profileCompletionPercentage;
    return completionPercentage >= 75 && _hasCriticalFields(profile);
  }

  // Check if profile has all critical fields completed
  static bool _hasCriticalFields(DoctorProfile profile) {
    return profile.medicalLicense.trim().isNotEmpty &&
        profile.medicalDegree.trim().isNotEmpty &&
        profile.specializations.isNotEmpty;
  }

  // Get validation message for UI display
  static String getValidationMessage(DoctorProfile profile) {
    if (profile.isProfileComplete) {
      return 'Your profile is complete and ready to accept appointments!';
    }

    final missingFields = profile.missingRequiredFields;
    final percentage = profile.profileCompletionPercentage;

    if (percentage < 50) {
      return 'Complete your basic information to get started. Missing: ${missingFields.take(3).join(', ')}${missingFields.length > 3 ? '...' : ''}';
    } else if (percentage < 75) {
      return 'You\'re halfway there! Complete these fields: ${missingFields.join(', ')}';
    } else {
      return 'Almost done! Just ${missingFields.length} more field${missingFields.length > 1 ? 's' : ''}: ${missingFields.join(', ')}';
    }
  }

  // Get list of critical missing fields that prevent accepting appointments
  static List<String> getCriticalMissingFields(DoctorProfile profile) {
    final missing = <String>[];

    if (profile.medicalLicense.trim().isEmpty) {
      missing.add('Medical License');
    }

    if (profile.medicalDegree.trim().isEmpty) {
      missing.add('Medical Degree');
    }

    if (profile.specializations.isEmpty) {
      missing.add('At least one specialization');
    }

    return missing;
  }

  // Get profile completion steps for UI guidance
  static List<ProfileCompletionStep> getCompletionSteps(DoctorProfile profile) {
    return [
      ProfileCompletionStep(
        title: 'Basic Information',
        description: 'Name, license, degree, and hospital affiliation',
        isCompleted:
            profile.fullName.trim().isNotEmpty &&
            profile.medicalLicense.trim().isNotEmpty &&
            profile.medicalDegree.trim().isNotEmpty &&
            profile.hospitalAffiliation.trim().isNotEmpty,
        fields: [
          'Full Name',
          'Medical License',
          'Medical Degree',
          'Hospital Affiliation',
        ],
      ),
      ProfileCompletionStep(
        title: 'Professional Details',
        description: 'Specializations, experience, and consultation fee',
        isCompleted:
            profile.specializations.isNotEmpty &&
            profile.yearsOfExperience > 0 &&
            profile.consultationFee > 0,
        fields: ['Specializations', 'Years of Experience', 'Consultation Fee'],
      ),
      ProfileCompletionStep(
        title: 'Practice Information',
        description: 'Clinic address and availability schedule',
        isCompleted:
            profile.clinicAddress.trim().isNotEmpty &&
            profile.weeklyAvailability.values.any((slots) => slots.isNotEmpty),
        fields: ['Clinic Address', 'Weekly Availability'],
      ),
    ];
  }
}

class ProfileCompletionStep {
  final String title;
  final String description;
  final bool isCompleted;
  final List<String> fields;

  const ProfileCompletionStep({
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.fields,
  });

  double get progress => isCompleted ? 1.0 : 0.0;
}
