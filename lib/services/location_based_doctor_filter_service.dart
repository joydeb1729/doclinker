import '../services/chat_service.dart';
import '../models/doctor_profile.dart';

/// Service to match doctor hospital affiliations with OSM hospital data using LLM
class LocationBasedDoctorFilterService {
  /// Filter doctors based on selected location hospitals using intelligent name matching
  static Future<List<DoctorProfile>> filterDoctorsByLocationHospitals({
    required List<DoctorProfile> allDoctors,
    required List<String> locationHospitalNames,
  }) async {
    if (locationHospitalNames.isEmpty) {
      return allDoctors; // No location filter active
    }

    try {
      // Create a comprehensive hospital matching prompt for the LLM
      final hospitalsListStr = locationHospitalNames
          .map((name) => '"$name"')
          .join(', ');
      final doctorsListStr = allDoctors
          .map((doctor) => '${doctor.uid}:"${doctor.hospitalAffiliation}"')
          .join(', ');

      final prompt =
          '''
You are a hospital name matching expert. I need you to match doctor hospital affiliations with a list of hospitals in a selected location.

LOCATION HOSPITALS: [$hospitalsListStr]

DOCTORS AND THEIR HOSPITALS: [$doctorsListStr]

Task: For each doctor, determine if their hospital affiliation matches any hospital in the location list. Hospital names may have slight variations, abbreviations, or different formats.

Consider these matching rules:
1. Exact matches (case-insensitive)
2. Partial matches (e.g., "Dhaka Medical College" matches "Dhaka Medical College Hospital")
3. Common abbreviations (e.g., "CMH" matches "Combined Military Hospital")
4. Location indicators (e.g., hospitals with same name but different locations like "Ibn Sina Hospital, Dhaka" vs "Ibn Sina Hospital Sylhet Ltd")
5. Institution type variations (e.g., "Hospital" vs "Medical College Hospital" vs "Clinic")

Return ONLY a JSON array of doctor UIDs that match hospitals in the location:
["uid1", "uid2", "uid3"]

If no matches found, return: []
''';

      // Get LLM response
      final response = await ChatService.sendMessage(prompt);

      // Parse the JSON response
      final matchedUids = _parseMatchedDoctorUids(response);

      // Filter doctors based on matched UIDs
      final filteredDoctors = allDoctors
          .where((doctor) => matchedUids.contains(doctor.uid))
          .toList();

      print(
        'LocationBasedDoctorFilterService: Filtered ${filteredDoctors.length}/${allDoctors.length} doctors based on location hospitals',
      );
      return filteredDoctors;
    } catch (e) {
      print('LocationBasedDoctorFilterService: Error filtering doctors: $e');
      // Fallback to simple string matching
      return _fallbackStringMatching(allDoctors, locationHospitalNames);
    }
  }

  /// Parse matched doctor UIDs from LLM response
  static List<String> _parseMatchedDoctorUids(String response) {
    try {
      // Extract JSON array from response
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']');

      if (jsonStart == -1 || jsonEnd == -1) {
        return [];
      }

      final jsonStr = response.substring(jsonStart, jsonEnd + 1);

      // Simple JSON parsing for array of strings
      final cleaned = jsonStr
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .replaceAll("'", '');

      if (cleaned.trim().isEmpty) {
        return [];
      }

      return cleaned
          .split(',')
          .map((uid) => uid.trim())
          .where((uid) => uid.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error parsing LLM response: $e');
      return [];
    }
  }

  /// Fallback string matching when LLM fails
  static List<DoctorProfile> _fallbackStringMatching(
    List<DoctorProfile> allDoctors,
    List<String> locationHospitalNames,
  ) {
    print('LocationBasedDoctorFilterService: Using fallback string matching');

    return allDoctors.where((doctor) {
      final doctorHospital = doctor.hospitalAffiliation.toLowerCase();

      // Check for any hospital name that contains or is contained in doctor's hospital
      for (final locationHospital in locationHospitalNames) {
        final locationHospitalLower = locationHospital.toLowerCase();

        // Exact match
        if (doctorHospital == locationHospitalLower) {
          return true;
        }

        // Partial matches
        if (doctorHospital.contains(locationHospitalLower) ||
            locationHospitalLower.contains(doctorHospital)) {
          return true;
        }

        // Check for common words (minimum 3 significant words match)
        final doctorWords = doctorHospital
            .split(' ')
            .where(
              (word) =>
                  word.length > 2 &&
                  ![
                    'the',
                    'and',
                    'ltd',
                    'pvt',
                    'hospital',
                    'medical',
                    'college',
                  ].contains(word),
            )
            .toSet();

        final locationWords = locationHospitalLower
            .split(' ')
            .where(
              (word) =>
                  word.length > 2 &&
                  ![
                    'the',
                    'and',
                    'ltd',
                    'pvt',
                    'hospital',
                    'medical',
                    'college',
                  ].contains(word),
            )
            .toSet();

        final commonWords = doctorWords.intersection(locationWords);
        if (commonWords.length >= 2) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  /// Quick check if doctor's hospital matches any location hospital
  static bool doesDoctorMatchLocation(
    DoctorProfile doctor,
    List<String> locationHospitalNames,
  ) {
    if (locationHospitalNames.isEmpty) return true;

    final doctorHospital = doctor.hospitalAffiliation.toLowerCase();

    for (final locationHospital in locationHospitalNames) {
      final locationHospitalLower = locationHospital.toLowerCase();

      if (doctorHospital == locationHospitalLower ||
          doctorHospital.contains(locationHospitalLower) ||
          locationHospitalLower.contains(doctorHospital)) {
        return true;
      }
    }

    return false;
  }
}
