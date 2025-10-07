import 'package:flutter_test/flutter_test.dart';
import '../lib/constants/hospital_constants.dart';

void main() {
  group('Hospital Matching Tests', () {
    // Simulate the _findMatchingHospital logic for testing
    String? findMatchingHospital(String originalHospital) {
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
            .replaceAll(RegExp(r'\\s+'), ' '); // Normalize whitespace

        String normalizedHospital = hospitalCore
            .replaceAll('  ', ' ')
            .replaceAll(RegExp(r'\\s+'), ' ');

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

    test('should match exact hospital names', () {
      const exactMatch = 'Khulna Medical College Hospital, Khulna';
      expect(findMatchingHospital(exactMatch), equals(exactMatch));
    });

    test('should handle typo in Khulna Medical College', () {
      const typoHospital =
          'Khulna Medical Collage Hospital'; // "Collage" instead of "College"
      const expectedMatch = 'Khulna Medical College Hospital, Khulna';
      expect(findMatchingHospital(typoHospital), equals(expectedMatch));
    });

    test('should return null for completely unmatched hospitals', () {
      const unmatchedHospital = 'Some Random Hospital That Does Not Exist';
      expect(findMatchingHospital(unmatchedHospital), isNull);
    });

    test('should handle empty hospital names', () {
      expect(findMatchingHospital(''), isNull);
    });

    test('should handle case insensitive matching', () {
      const lowerCaseHospital = 'dhaka medical college & hospital';
      const expectedMatch = 'Dhaka Medical College & Hospital';
      expect(findMatchingHospital(lowerCaseHospital), equals(expectedMatch));
    });

    test('should verify no duplicate hospital names in constants', () {
      final hospitalSet = <String>{};
      final duplicates = <String>[];

      for (String hospital in HospitalConstants.bangladeshHospitals) {
        if (hospitalSet.contains(hospital)) {
          duplicates.add(hospital);
        } else {
          hospitalSet.add(hospital);
        }
      }

      expect(
        duplicates,
        isEmpty,
        reason: 'Found duplicate hospitals: ${duplicates.join(', ')}',
      );
    });
  });
}
