import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_profile.dart';
import 'embedding_service.dart';
import 'chat_service.dart';

class DoctorMatchingService {
  static const String _baseUrl =
      'http://10.0.2.2:8000'; // For symptom analysis API
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Medical assistant for "Find Doctor" mode - analyzes symptoms and suggests specialties
  static Future<SpecialtyRecommendation> analyzeSymptomsAndSuggestSpecialties(
    String symptoms,
  ) async {
    try {
      final prompt =
          '''
You are a helpful AI medical assistant in a "Find Doctor" feature. 
Your role is to guide users to the correct type of doctor based on their described symptoms.

User symptoms: $symptoms

Your tasks:
1. Interpret the symptoms and suggest the most likely condition or category in plain words (e.g., "headache", "migraine", "knee pain").
2. Identify the most relevant medical specialty or specialties (e.g., Neurology, Orthopedics, Dermatology).
3. Provide a clear, short explanation for the user.

Available specialties: Cardiology, Dermatology, Endocrinology, Gastroenterology, General Medicine, Internal Medicine, Neurology, Orthopedics, Pediatrics, Psychiatry, Pulmonology, Urology, Gynecology, Ophthalmology, ENT, Oncology, Rheumatology.

Important rules:
- Do NOT attempt a medical diagnosis. Only suggest the specialty.
- Prioritize specific specialties over General Medicine when possible.
- Only include "General Medicine" if the symptoms are truly general or unclear.
- For specific conditions like heart problems, suggest Cardiology (not General Medicine).
- Keep explanations clear and easy to understand.
- Maximum 2 specialties to ensure precision.

Format your response as JSON:
{
  "explanation": "Based on your symptoms, you should visit a doctor specialized in [specialty].",
  "condition": "Short condition/category word like 'Headache', 'Migraine', 'Back pain'",
  "specialties": ["Primary Specialty"]
}
''';

      final response = await ChatService.sendMessage(prompt);

      // Parse the JSON response
      final cleanResponse = response.trim();
      // Handle potential JSON wrapped in markdown code blocks
      final jsonString = cleanResponse
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final Map<String, dynamic> jsonResponse = jsonDecode(jsonString);

      return SpecialtyRecommendation(
        explanation: jsonResponse['explanation'] ?? '',
        condition: jsonResponse['condition'] ?? '',
        specialties: List<String>.from(jsonResponse['specialties'] ?? []),
      );
    } catch (e) {
      print('Error in medical assistant analysis: $e');
      // Fallback to keyword-based suggestions
      return _getFallbackSpecialtyRecommendation(symptoms);
    }
  }

  // Fallback recommendation when LLM fails
  static SpecialtyRecommendation _getFallbackSpecialtyRecommendation(
    String symptoms,
  ) {
    final symptomsLower = symptoms.toLowerCase();

    if (symptomsLower.contains('head') ||
        symptomsLower.contains('brain') ||
        symptomsLower.contains('migraine') ||
        symptomsLower.contains('dizziness')) {
      return SpecialtyRecommendation(
        explanation:
            "Based on your symptoms, you should visit a doctor specialized in Neurology.",
        condition: "Headache",
        specialties: ["Neurology"],
      );
    }

    if (symptomsLower.contains('heart') ||
        symptomsLower.contains('chest') ||
        symptomsLower.contains('cardiac') ||
        symptomsLower.contains('surgery')) {
      return SpecialtyRecommendation(
        explanation:
            "Based on your symptoms, you should visit a doctor specialized in Cardiology.",
        condition: "Heart issue",
        specialties: ["Cardiology"],
      );
    }

    if (symptomsLower.contains('bone') ||
        symptomsLower.contains('joint') ||
        symptomsLower.contains('knee') ||
        symptomsLower.contains('back')) {
      return SpecialtyRecommendation(
        explanation:
            "Based on your symptoms, you should visit a doctor specialized in Orthopedics.",
        condition: "Joint pain",
        specialties: ["Orthopedics"],
      );
    }

    if (symptomsLower.contains('skin') ||
        symptomsLower.contains('rash') ||
        symptomsLower.contains('acne')) {
      return SpecialtyRecommendation(
        explanation:
            "Based on your symptoms, you should visit a doctor specialized in Dermatology.",
        condition: "Skin issue",
        specialties: ["Dermatology"],
      );
    }

    // Default fallback
    return SpecialtyRecommendation(
      explanation:
          "Based on your symptoms, you should visit a doctor specialized in General Medicine.",
      condition: "General health concern",
      specialties: ["General Medicine"],
    );
  }

  // RAG-based doctor matching using Firestore embeddings
  static Future<DoctorMatchingResult> findMatchingDoctors({
    required String symptoms,
    required String location,
    int maxResults = 5,
  }) async {
    try {
      // Step 1: Get embedding for user symptoms
      final symptomEmbedding = await _getSymptomEmbedding(symptoms);

      // Step 2: Get all doctors from Firestore
      // For now, only require isActive (remove isVerified requirement for testing)
      final doctorsQuery = await _firestore
          .collection('doctor_profiles')
          .where('isActive', isEqualTo: true)
          .get();

      print('🔍 Found ${doctorsQuery.docs.length} active doctors in database');

      // Step 3: Calculate similarity scores and create matched doctors
      List<MatchedDoctor> matchedDoctors = [];
      int doctorsWithEmbeddings = 0;
      int doctorsWithoutEmbeddings = 0;

      for (var doc in doctorsQuery.docs) {
        try {
          final doctorProfile = DoctorProfile.fromFirestore(doc);
          print('👨‍⚕️ Processing doctor: ${doctorProfile.fullName}');

          // Check if embedding is available
          if (doctorProfile.profileEmbedding == null ||
              doctorProfile.profileEmbedding!.isEmpty) {
            doctorsWithoutEmbeddings++;
            print(
              '❌ Doctor ${doctorProfile.fullName} has no embedding - skipping',
            );
            continue;
          }

          doctorsWithEmbeddings++;
          print(
            '✅ Doctor ${doctorProfile.fullName} has embedding with ${doctorProfile.profileEmbedding!.length} dimensions',
          );

          // Calculate cosine similarity
          final similarity = _calculateCosineSimilarity(
            symptomEmbedding,
            doctorProfile.profileEmbedding!,
          );

          // Convert to MatchedDoctor if similarity is above threshold
          if (similarity >= 0.1) {
            // Minimum 10% relevance
            final matchedDoctor = _convertToMatchedDoctor(
              doctorProfile,
              similarity,
              location,
            );
            matchedDoctors.add(matchedDoctor);
          }
        } catch (e) {
          print('Error processing doctor ${doc.id}: $e');
          continue;
        }
      }

      // Step 4: Sort by similarity score and limit results
      matchedDoctors.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      if (matchedDoctors.length > maxResults) {
        matchedDoctors = matchedDoctors.take(maxResults).toList();
      }

      // Print summary
      print('📊 Matching Summary:');
      print('   - Total active doctors: ${doctorsQuery.docs.length}');
      print('   - Doctors with embeddings: $doctorsWithEmbeddings');
      print('   - Doctors without embeddings: $doctorsWithoutEmbeddings');
      print('   - Successfully matched: ${matchedDoctors.length}');

      return DoctorMatchingResult(
        query: symptoms,
        matchedDoctors: matchedDoctors,
        totalResults: matchedDoctors.length,
        processingTime: '${DateTime.now().millisecondsSinceEpoch % 1000}ms',
        suggestions: _getFollowUpSuggestions(symptoms),
      );
    } catch (e) {
      throw Exception('RAG matching failed: $e');
    }
  }

  // Specialty-based doctor matching for "Find Doctor" mode
  static Future<DoctorMatchingResult> findDoctorsBySpecialties({
    required List<String> specialties,
    required String location,
    required String originalQuery,
    int maxResults = 5,
  }) async {
    try {
      // Get all active doctors from Firestore
      final doctorsQuery = await _firestore
          .collection('doctor_profiles')
          .where('isActive', isEqualTo: true)
          .get();

      print('🔍 Found ${doctorsQuery.docs.length} active doctors in database');
      print('🎯 Searching for specialties: ${specialties.join(', ')}');

      // Match doctors by specialty
      List<MatchedDoctor> matchedDoctors = [];

      for (var doc in doctorsQuery.docs) {
        try {
          final doctorProfile = DoctorProfile.fromFirestore(doc);

          // Calculate specialty match score
          double matchScore = _calculateSpecialtyMatch(
            doctorProfile,
            specialties,
          );

          print(
            '🔄 Evaluating: ${doctorProfile.fullName} (${doctorProfile.specializations.join(', ')}) vs ${specialties.join(', ')} - Score: ${(matchScore * 100).toInt()}%',
          );

          // Only include doctors with meaningful match scores (50% or higher)
          if (matchScore >= 0.5) {
            final matchedDoctor = _convertToMatchedDoctor(
              doctorProfile,
              matchScore,
              location,
            );
            matchedDoctors.add(matchedDoctor);
            print(
              '✅ MATCHED: ${doctorProfile.fullName} - Final Score: ${(matchScore * 100).toInt()}%',
            );
          } else {
            print('❌ NO MATCH: ${doctorProfile.fullName} - Score too low');
          }
        } catch (e) {
          print('❌ Error processing doctor profile: $e');
          continue;
        }
      }

      // Sort by match score (highest first) and limit results
      matchedDoctors.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      matchedDoctors = matchedDoctors.take(maxResults).toList();

      print('📊 Final results: ${matchedDoctors.length} doctors matched');

      return DoctorMatchingResult(
        query: originalQuery,
        matchedDoctors: matchedDoctors,
        totalResults: matchedDoctors.length,
        processingTime: '${DateTime.now().millisecondsSinceEpoch % 1000}ms',
        suggestions: _getFollowUpSuggestions(originalQuery),
      );
    } catch (e) {
      throw Exception('Specialty-based doctor search failed: $e');
    }
  }

  // Calculate specialty match score for a doctor
  static double _calculateSpecialtyMatch(
    DoctorProfile doctor,
    List<String> targetSpecialties,
  ) {
    if (targetSpecialties.isEmpty || doctor.specializations.isEmpty) {
      return 0.0;
    }

    // Separate specific and general specialties
    final specificSpecialties = targetSpecialties
        .where((s) => s.toLowerCase() != 'general medicine')
        .toList();
    final hasGeneralMedicine = targetSpecialties.any(
      (s) => s.toLowerCase() == 'general medicine',
    );

    double maxScore = 0.0;
    bool foundSpecificMatch = false;

    // First, try to match specific specialties (higher priority)
    for (String targetSpecialty in specificSpecialties) {
      for (String doctorSpecialty in doctor.specializations) {
        double score = 0.0;

        // Exact match for specific specialty gets highest score
        if (targetSpecialty.toLowerCase() == doctorSpecialty.toLowerCase()) {
          score = 1.0;
          foundSpecificMatch = true;
        }
        // Partial match for specific specialty
        else if (doctorSpecialty.toLowerCase().contains(
              targetSpecialty.toLowerCase(),
            ) ||
            targetSpecialty.toLowerCase().contains(
              doctorSpecialty.toLowerCase(),
            )) {
          score = 0.8;
          foundSpecificMatch = true;
        }
        // Related specialty matches
        else {
          final relatedScore = _getRelatedSpecialtyScore(
            targetSpecialty,
            doctorSpecialty,
          );
          if (relatedScore > 0) {
            score = relatedScore;
            foundSpecificMatch = true;
          }
        }

        maxScore = math.max(maxScore, score);
      }
    }

    // If no specific match found and General Medicine is requested,
    // give lower score for doctors with only General Medicine
    if (!foundSpecificMatch && hasGeneralMedicine) {
      for (String doctorSpecialty in doctor.specializations) {
        if (doctorSpecialty.toLowerCase() == 'general medicine') {
          // Lower score for general medicine when specific specialty was requested
          maxScore = math.max(
            maxScore,
            specificSpecialties.isNotEmpty ? 0.3 : 0.7,
          );
          break;
        }
      }
    }

    return maxScore;
  }

  // Get score for related specialties
  static double _getRelatedSpecialtyScore(String target, String doctor) {
    final targetLower = target.toLowerCase();
    final doctorLower = doctor.toLowerCase();

    // Internal Medicine and General Medicine are closely related
    if ((targetLower == 'internal medicine' &&
            doctorLower == 'general medicine') ||
        (targetLower == 'general medicine' &&
            doctorLower == 'internal medicine')) {
      return 0.9;
    }

    // ENT specialties
    if (targetLower == 'ent' &&
        (doctorLower.contains('otolaryngology') ||
            doctorLower.contains('ear') ||
            doctorLower.contains('nose') ||
            doctorLower.contains('throat'))) {
      return 0.9;
    }

    // Orthopedics variations
    if (targetLower == 'orthopedics' &&
        (doctorLower.contains('orthopedic') ||
            doctorLower.contains('bone') ||
            doctorLower.contains('joint'))) {
      return 0.8;
    }

    return 0.0;
  }

  // Get embedding for user symptoms using HuggingFace API
  static Future<List<double>> _getSymptomEmbedding(String symptoms) async {
    // Use the EmbeddingService for consistent embedding generation
    return await EmbeddingService.generateSymptomEmbedding(symptoms);
  }

  // Calculate cosine similarity between two embeddings
  static double _calculateCosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }

  // Convert DoctorProfile to MatchedDoctor with similarity score
  static MatchedDoctor _convertToMatchedDoctor(
    DoctorProfile profile,
    double similarity,
    String location,
  ) {
    // Calculate distance (mock for now - you can integrate real geolocation)
    final distance =
        '${(math.Random().nextDouble() * 5 + 0.5).toStringAsFixed(1)} km';

    // Determine availability
    final isAvailableToday = math.Random().nextBool();
    final nextAvailable = isAvailableToday
        ? 'Today ${_getRandomTimeSlot()}'
        : 'Tomorrow ${_getRandomTimeSlot()}';

    return MatchedDoctor(
      id: profile.uid,
      name: profile.fullName,
      specialty: profile.specializations.isNotEmpty
          ? profile.specializations.first
          : 'General Medicine',
      subSpecialties: profile.specializations.length > 1
          ? profile.specializations.skip(1).toList()
          : [],
      rating: profile.averageRating > 0 ? profile.averageRating : 4.5,
      reviewCount: profile.totalReviews > 0 ? profile.totalReviews : 50,
      distance: distance,
      matchScore: similarity,
      yearsExperience: profile.yearsOfExperience,
      education: profile.medicalDegree,
      hospitalAffiliation: profile.hospitalAffiliation,
      consultationFee: profile.consultationFee,
      availableToday: isAvailableToday,
      nextAvailable: nextAvailable,
      profileImage: profile.profileImageUrl,
    );
  }

  // Get random time slot for availability
  static String _getRandomTimeSlot() {
    final slots = [
      '9:00 AM',
      '10:00 AM',
      '11:00 AM',
      '2:00 PM',
      '3:00 PM',
      '4:00 PM',
      '5:00 PM',
    ];
    return slots[math.Random().nextInt(slots.length)];
  }

  // Analyze symptoms and extract medical entities
  static Future<SymptomAnalysis> analyzeSymptoms(String symptoms) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/analyze-symptoms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'symptoms': symptoms}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SymptomAnalysis.fromJson(data);
      } else {
        throw Exception('Failed to analyze symptoms: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback analysis
      return _getMockSymptomAnalysis(symptoms);
    }
  }

  // Book appointment with selected doctor
  static Future<AppointmentBookingResult> bookAppointment({
    required String doctorId,
    required String patientId,
    required DateTime appointmentDate,
    required String timeSlot,
    required String symptoms,
    String? additionalNotes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/book-appointment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctor_id': doctorId,
          'patient_id': patientId,
          'appointment_date': appointmentDate.toIso8601String(),
          'time_slot': timeSlot,
          'symptoms': symptoms,
          'additional_notes': additionalNotes,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AppointmentBookingResult.fromJson(data);
      } else {
        throw Exception('Failed to book appointment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Booking failed: $e');
    }
  }

  // Get available time slots for a doctor
  static Future<List<String>> getAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/doctor/$doctorId/available-slots?date=${date.toIso8601String()}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['available_slots']);
      } else {
        throw Exception(
          'Failed to get available slots: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Return mock slots for development
      return [
        '09:00 - 09:30',
        '10:00 - 10:30',
        '11:00 - 11:30',
        '14:00 - 14:30',
        '15:00 - 15:30',
        '16:00 - 16:30',
      ];
    }
  }

  static SymptomAnalysis _getMockSymptomAnalysis(String symptoms) {
    final lowerSymptoms = symptoms.toLowerCase();

    List<String> extractedSymptoms = [];
    List<String> medicalEntities = [];
    UrgencyLevel urgencyLevel = UrgencyLevel.low;
    List<String> suggestedSpecialties = [];
    List<String> recommendations = [];

    if (lowerSymptoms.contains('headache') ||
        lowerSymptoms.contains('migraine')) {
      extractedSymptoms = ['headache', 'head pain'];
      medicalEntities = ['neurological symptoms'];
      urgencyLevel = UrgencyLevel.low;
      suggestedSpecialties = ['Neurologist', 'General Physician'];
      recommendations = [
        'Rest in a dark, quiet room',
        'Stay hydrated',
        'Consider over-the-counter pain relief',
      ];
    } else if (lowerSymptoms.contains('chest pain') ||
        lowerSymptoms.contains('heart')) {
      extractedSymptoms = ['chest pain', 'cardiac symptoms'];
      medicalEntities = ['cardiovascular symptoms'];
      urgencyLevel = UrgencyLevel.high;
      suggestedSpecialties = ['Cardiologist', 'Emergency Medicine'];
      recommendations = [
        'Seek immediate medical attention',
        'Avoid physical exertion',
        'Monitor vital signs',
      ];
    } else if (lowerSymptoms.contains('fever') ||
        lowerSymptoms.contains('cold')) {
      extractedSymptoms = ['fever', 'cold symptoms'];
      medicalEntities = ['infectious disease symptoms'];
      urgencyLevel = UrgencyLevel.moderate;
      suggestedSpecialties = ['General Physician', 'Internal Medicine'];
      recommendations = [
        'Rest and stay hydrated',
        'Monitor temperature',
        'Isolate to prevent spread',
      ];
    } else {
      extractedSymptoms = [symptoms];
      medicalEntities = ['general symptoms'];
      urgencyLevel = UrgencyLevel.low;
      suggestedSpecialties = ['General Physician'];
      recommendations = [
        'Monitor symptoms closely',
        'Maintain healthy lifestyle',
        'Consult doctor if symptoms worsen',
      ];
    }

    return SymptomAnalysis(
      originalText: symptoms,
      extractedSymptoms: extractedSymptoms,
      medicalEntities: medicalEntities,
      urgencyLevel: urgencyLevel,
      suggestedSpecialties: suggestedSpecialties,
      confidence: 0.85,
      recommendations: recommendations,
    );
  }

  static List<String> _getFollowUpSuggestions(String symptoms) {
    return [
      'Book appointment with recommended doctor',
      'Get more information about the condition',
      'Find emergency care if urgent',
      'Ask follow-up questions about symptoms',
    ];
  }

  /// Generate embeddings for a specific doctor and save to Firestore
  static Future<void> generateEmbeddingForDoctor(String doctorId) async {
    try {
      final doc = await _firestore
          .collection('doctor_profiles')
          .doc(doctorId)
          .get();

      if (!doc.exists) {
        print('❌ Doctor with ID $doctorId not found');
        return;
      }

      final doctorProfile = DoctorProfile.fromFirestore(doc);
      print('🔄 Generating embedding for ${doctorProfile.fullName}...');

      final embedding = await EmbeddingService.generateDoctorEmbedding(
        doctorProfile,
      );

      await _firestore.collection('doctor_profiles').doc(doctorId).update({
        'profileEmbedding': embedding,
      });

      print(
        '✅ Successfully generated and saved embedding for ${doctorProfile.fullName}',
      );
    } catch (e) {
      print('❌ Failed to generate embedding: $e');
    }
  }
}

// Data models for medical assistant and RAG responses
class SpecialtyRecommendation {
  final String explanation;
  final String condition;
  final List<String> specialties;

  SpecialtyRecommendation({
    required this.explanation,
    required this.condition,
    required this.specialties,
  });
}

class DoctorMatchingResult {
  final String query;
  final List<MatchedDoctor> matchedDoctors;
  final int totalResults;
  final String processingTime;
  final List<String> suggestions;

  DoctorMatchingResult({
    required this.query,
    required this.matchedDoctors,
    required this.totalResults,
    required this.processingTime,
    required this.suggestions,
  });

  factory DoctorMatchingResult.fromJson(Map<String, dynamic> json) {
    return DoctorMatchingResult(
      query: json['query'] ?? '',
      matchedDoctors: (json['matched_doctors'] as List)
          .map((doctor) => MatchedDoctor.fromJson(doctor))
          .toList(),
      totalResults: json['total_results'] ?? 0,
      processingTime: json['processing_time'] ?? '0s',
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}

class MatchedDoctor {
  final String id;
  final String name;
  final String specialty;
  final List<String> subSpecialties;
  final double rating;
  final int reviewCount;
  final String distance;
  final double matchScore;
  final int yearsExperience;
  final String education;
  final String hospitalAffiliation;
  final double consultationFee;
  final bool availableToday;
  final String nextAvailable;
  final String? profileImage;

  MatchedDoctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.subSpecialties,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.matchScore,
    required this.yearsExperience,
    required this.education,
    required this.hospitalAffiliation,
    required this.consultationFee,
    required this.availableToday,
    required this.nextAvailable,
    this.profileImage,
  });

  factory MatchedDoctor.fromJson(Map<String, dynamic> json) {
    return MatchedDoctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      subSpecialties: List<String>.from(json['sub_specialties'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      distance: json['distance'] ?? '',
      matchScore: (json['match_score'] ?? 0.0).toDouble(),
      yearsExperience: json['years_experience'] ?? 0,
      education: json['education'] ?? '',
      hospitalAffiliation: json['hospital_affiliation'] ?? '',
      consultationFee: (json['consultation_fee'] ?? 0.0).toDouble(),
      availableToday: json['available_today'] ?? false,
      nextAvailable: json['next_available'] ?? '',
      profileImage: json['profile_image'],
    );
  }
}

class SymptomAnalysis {
  final String originalText;
  final List<String> extractedSymptoms;
  final List<String> medicalEntities;
  final UrgencyLevel urgencyLevel;
  final List<String> suggestedSpecialties;
  final double confidence;
  final List<String> recommendations;

  SymptomAnalysis({
    required this.originalText,
    required this.extractedSymptoms,
    required this.medicalEntities,
    required this.urgencyLevel,
    required this.suggestedSpecialties,
    required this.confidence,
    required this.recommendations,
  });

  factory SymptomAnalysis.fromJson(Map<String, dynamic> json) {
    return SymptomAnalysis(
      originalText: json['original_text'] ?? '',
      extractedSymptoms: List<String>.from(json['extracted_symptoms'] ?? []),
      medicalEntities: List<String>.from(json['medical_entities'] ?? []),
      urgencyLevel: _parseUrgencyLevel(json['urgency_level']),
      suggestedSpecialties: List<String>.from(
        json['suggested_specialties'] ?? [],
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  static UrgencyLevel _parseUrgencyLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return UrgencyLevel.high;
      case 'moderate':
        return UrgencyLevel.moderate;
      default:
        return UrgencyLevel.low;
    }
  }
}

enum UrgencyLevel { low, moderate, high }

class AppointmentBookingResult {
  final bool success;
  final String? appointmentId;
  final String message;
  final DateTime? appointmentDate;
  final String? timeSlot;

  AppointmentBookingResult({
    required this.success,
    this.appointmentId,
    required this.message,
    this.appointmentDate,
    this.timeSlot,
  });

  factory AppointmentBookingResult.fromJson(Map<String, dynamic> json) {
    return AppointmentBookingResult(
      success: json['success'] ?? false,
      appointmentId: json['appointment_id'],
      message: json['message'] ?? '',
      appointmentDate: json['appointment_date'] != null
          ? DateTime.parse(json['appointment_date'])
          : null,
      timeSlot: json['time_slot'],
    );
  }
}
