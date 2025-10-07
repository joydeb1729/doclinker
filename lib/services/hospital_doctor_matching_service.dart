import '../models/doctor_profile.dart';
import '../constants/hospital_constants.dart';
import '../models/hospital_profile.dart';

/// Service to help match doctors with real hospitals from OSM data
class HospitalDoctorMatchingService {
  /// Find doctors working at a specific hospital
  static Future<List<DoctorProfile>> getDoctorsByHospital(
    String hospitalName,
    List<DoctorProfile> allDoctors,
  ) async {
    return allDoctors.where((doctor) {
      // Exact match
      if (doctor.hospitalAffiliation == hospitalName) {
        return true;
      }

      // Fuzzy match - check if doctor's hospital contains the searched hospital name
      // This helps with variations in naming
      final doctorHospital = doctor.hospitalAffiliation.toLowerCase();
      final searchHospital = hospitalName.toLowerCase();

      return doctorHospital.contains(searchHospital) ||
          searchHospital.contains(doctorHospital);
    }).toList();
  }

  /// Find hospitals that have doctors available
  static Future<List<HospitalProfile>> getHospitalsWithDoctors(
    List<HospitalProfile> hospitals,
    List<DoctorProfile> allDoctors,
  ) async {
    List<HospitalProfile> hospitalsWithDoctors = [];

    for (final hospital in hospitals) {
      final doctorsAtHospital = await getDoctorsByHospital(
        hospital.name,
        allDoctors,
      );
      if (doctorsAtHospital.isNotEmpty) {
        // Create a copy of hospital with doctor count
        hospitalsWithDoctors.add(hospital);
      }
    }

    return hospitalsWithDoctors;
  }

  /// Get statistics about doctor-hospital matching
  static Future<Map<String, dynamic>> getHospitalDoctorStats(
    List<HospitalProfile> hospitals,
    List<DoctorProfile> allDoctors,
  ) async {
    int totalHospitals = hospitals.length;
    int hospitalsWithDoctors = 0;
    int totalDoctors = allDoctors.length;
    int doctorsWithValidHospitals = 0;

    Map<String, int> doctorCountByHospital = {};

    // Count doctors with valid hospitals
    for (final doctor in allDoctors) {
      if (HospitalConstants.bangladeshHospitals.contains(
        doctor.hospitalAffiliation,
      )) {
        doctorsWithValidHospitals++;
      }
    }

    // Count doctors per hospital
    for (final hospital in hospitals) {
      final doctorsAtHospital = await getDoctorsByHospital(
        hospital.name,
        allDoctors,
      );
      if (doctorsAtHospital.isNotEmpty) {
        hospitalsWithDoctors++;
        doctorCountByHospital[hospital.name] = doctorsAtHospital.length;
      }
    }

    return {
      'totalHospitals': totalHospitals,
      'hospitalsWithDoctors': hospitalsWithDoctors,
      'totalDoctors': totalDoctors,
      'doctorsWithValidHospitals': doctorsWithValidHospitals,
      'doctorCountByHospital': doctorCountByHospital,
      'averageDoctorsPerHospital': hospitalsWithDoctors > 0
          ? (doctorsWithValidHospitals / hospitalsWithDoctors).toStringAsFixed(
              2,
            )
          : '0',
    };
  }

  /// Suggest hospital corrections for doctors with invalid hospital names
  static List<String> suggestHospitalCorrections(String invalidHospitalName) {
    if (HospitalConstants.bangladeshHospitals.contains(invalidHospitalName)) {
      return []; // Already valid
    }

    final suggestions = HospitalConstants.searchHospitals(invalidHospitalName);

    // If no direct matches, try to find similar names
    if (suggestions.isEmpty) {
      final words = invalidHospitalName.toLowerCase().split(' ');
      Set<String> potentialMatches = {};

      for (final word in words) {
        if (word.length > 2) {
          final matches = HospitalConstants.bangladeshHospitals.where(
            (hospital) => hospital.toLowerCase().contains(word),
          );
          potentialMatches.addAll(matches);
        }
      }

      return potentialMatches.toList();
    }

    return suggestions.take(5).toList(); // Limit to top 5 suggestions
  }
}
