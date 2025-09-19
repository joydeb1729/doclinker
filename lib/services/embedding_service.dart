import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/doctor_profile.dart';
import '../config/app_config.dart';

class EmbeddingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate embedding for doctor profile using HuggingFace API
  static Future<List<double>> generateDoctorEmbedding(
    DoctorProfile doctor,
  ) async {
    try {
      // Create a comprehensive text representation of the doctor
      final profileText = _createDoctorProfileText(doctor);

      print('Generating embedding for: ${doctor.fullName}');
      print(
        'Profile text: ${profileText.substring(0, min(100, profileText.length))}...',
      );

      // Use HuggingFace Inference API
      final embedding = await _getEmbeddingFromHuggingFace(profileText);

      print(
        '✅ Successfully generated embedding with ${embedding.length} dimensions',
      );
      return embedding;
    } catch (e) {
      print('⚠️ HuggingFace embedding failed for ${doctor.fullName}: $e');
      print('Using fallback embedding generation...');

      // Fallback: Generate deterministic embedding based on doctor data
      return _generateFallbackEmbedding(doctor);
    }
  }

  /// Generate embedding for symptoms using HuggingFace API
  static Future<List<double>> generateSymptomEmbedding(String symptoms) async {
    try {
      print(
        'Generating embedding for symptoms: ${symptoms.substring(0, min(50, symptoms.length))}...',
      );

      // Use HuggingFace Inference API
      final embedding = await _getEmbeddingFromHuggingFace(symptoms);

      print(
        '✅ Successfully generated symptom embedding with ${embedding.length} dimensions',
      );
      return embedding;
    } catch (e) {
      print('⚠️ HuggingFace symptom embedding failed: $e');
      print('Using fallback embedding generation...');

      // Fallback: Generate deterministic embedding for symptoms
      return _generateFallbackEmbeddingFromText(symptoms);
    }
  }

  /// Call HuggingFace Inference API for feature extraction
  static Future<List<double>> _getEmbeddingFromHuggingFace(String text) async {
    if (!AppConfig.useHuggingFace ||
        AppConfig.huggingFaceApiKey == 'YOUR_HF_API_KEY_HERE') {
      throw Exception('HuggingFace API key not configured');
    }

    final url = Uri.parse(
      '${AppConfig.huggingFaceBaseUrl}/models/${AppConfig.embeddingModelId}',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer ${AppConfig.huggingFaceApiKey}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'inputs': text,
            'options': {'wait_for_model': true},
          }),
        )
        .timeout(AppConfig.requestTimeout);

    if (response.statusCode == 200) {
      final dynamic responseData = jsonDecode(response.body);

      // HuggingFace returns different formats, handle both
      if (responseData is List && responseData.isNotEmpty) {
        // Handle nested array format: [[embedding]]
        final firstElement = responseData[0];
        if (firstElement is List) {
          return List<double>.from(firstElement);
        }
        // Handle flat array format: [embedding]
        return List<double>.from(responseData);
      } else if (responseData is Map &&
          responseData.containsKey('embeddings')) {
        // Handle object format: {embeddings: [embedding]}
        return List<double>.from(responseData['embeddings'][0]);
      } else {
        throw Exception(
          'Unexpected response format: ${responseData.runtimeType}',
        );
      }
    } else if (response.statusCode == 503) {
      // Model is loading, wait and retry
      await Future.delayed(const Duration(seconds: 2));
      throw Exception('Model is loading, please retry in a moment');
    } else {
      throw Exception(
        'HuggingFace API error: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Create comprehensive text representation for embedding generation
  static String _createDoctorProfileText(DoctorProfile doctor) {
    final textParts = <String>[
      // Core specializations
      ...doctor.specializations,

      // Medical degree and education
      doctor.medicalDegree,

      // Hospital affiliation
      doctor.hospitalAffiliation,

      // Expertise keywords if available
      if (doctor.expertiseKeywords != null &&
          doctor.expertiseKeywords!.isNotEmpty)
        ...doctor.expertiseKeywords!,

      // Treatment methods if available
      if (doctor.treatmentMethods != null &&
          doctor.treatmentMethods!.isNotEmpty)
        ...doctor.treatmentMethods!,

      // Experience level indicator
      if (doctor.yearsOfExperience >= 15) 'senior consultant',
      if (doctor.yearsOfExperience >= 20) 'expert physician',
      if (doctor.yearsOfExperience < 5) 'junior doctor',

      // Additional context
      'medical professional',
      'healthcare provider',
      'clinical practice',
    ];

    return textParts
        .where((text) => text.isNotEmpty)
        .join(' ')
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special characters
        .trim();
  }

  /// Generate deterministic fallback embedding based on doctor profile
  static List<double> _generateFallbackEmbedding(DoctorProfile doctor) {
    final profileText = _createDoctorProfileText(doctor);
    return _generateFallbackEmbeddingFromText(profileText);
  }

  /// Generate deterministic fallback embedding based on text content
  static List<double> _generateFallbackEmbeddingFromText(String text) {
    final random = Random(text.hashCode); // Deterministic based on content

    // Generate embedding with configured dimensions
    return List.generate(AppConfig.embeddingDimensions, (index) {
      // Create somewhat realistic distribution
      final value = random.nextGaussian() * 0.3; // Standard normal scaled
      return value.clamp(-1.0, 1.0); // Clamp to reasonable range
    });
  }

  /// Update all doctor profiles in Firestore with embeddings
  static Future<void> generateEmbeddingsForAllDoctors() async {
    try {
      final doctorsSnapshot = await _firestore
          .collection('doctor_profiles')
          .where('isVerified', isEqualTo: true)
          .get();

      print('Found ${doctorsSnapshot.docs.length} verified doctors');

      for (var doc in doctorsSnapshot.docs) {
        try {
          final doctor = DoctorProfile.fromFirestore(doc);

          // Skip if embedding already exists
          if (doctor.profileEmbedding != null &&
              doctor.profileEmbedding!.isNotEmpty) {
            print('Skipping ${doctor.fullName} - embedding already exists');
            continue;
          }

          print('Generating embedding for ${doctor.fullName}...');

          // Generate embedding
          final embedding = await generateDoctorEmbedding(doctor);

          // Generate expertise keywords and treatment methods if not present
          final expertiseKeywords =
              doctor.expertiseKeywords ?? generateExpertiseKeywords(doctor);
          final treatmentMethods =
              doctor.treatmentMethods ?? generateTreatmentMethods(doctor);

          // Update doctor profile with embedding and enhanced metadata
          await doc.reference.update({
            'profileEmbedding': embedding,
            'expertiseKeywords': expertiseKeywords,
            'treatmentMethods': treatmentMethods,
            'embeddingGeneratedAt': FieldValue.serverTimestamp(),
          });

          print('✅ Updated ${doctor.fullName}');

          // Add small delay to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          print('❌ Error processing doctor ${doc.id}: $e');
          continue;
        }
      }

      print('🎉 Embedding generation completed!');
    } catch (e) {
      print('Error in batch embedding generation: $e');
      throw e;
    }
  }

  /// Generate expertise keywords based on specializations
  static List<String> generateExpertiseKeywords(DoctorProfile doctor) {
    final keywords = <String>[];

    for (final specialization in doctor.specializations) {
      final spec = specialization.toLowerCase();

      if (spec.contains('cardio')) {
        keywords.addAll([
          'heart disease',
          'cardiac care',
          'chest pain',
          'heart attack',
          'hypertension',
        ]);
      } else if (spec.contains('neuro')) {
        keywords.addAll([
          'headache',
          'migraine',
          'stroke',
          'epilepsy',
          'brain disorders',
        ]);
      } else if (spec.contains('ortho')) {
        keywords.addAll([
          'bone fracture',
          'joint pain',
          'back pain',
          'sports injury',
          'arthritis',
        ]);
      } else if (spec.contains('dermato')) {
        keywords.addAll([
          'skin problems',
          'acne',
          'rash',
          'eczema',
          'psoriasis',
        ]);
      } else if (spec.contains('pediatr')) {
        keywords.addAll([
          'child health',
          'vaccination',
          'growth problems',
          'pediatric care',
        ]);
      } else if (spec.contains('gyneco') || spec.contains('obstet')) {
        keywords.addAll([
          'womens health',
          'pregnancy',
          'menstrual problems',
          'fertility',
        ]);
      } else if (spec.contains('ophthal')) {
        keywords.addAll([
          'eye problems',
          'vision loss',
          'cataract',
          'glaucoma',
        ]);
      } else if (spec.contains('ent')) {
        keywords.addAll([
          'throat infection',
          'hearing loss',
          'sinus problems',
          'tonsillitis',
        ]);
      } else if (spec.contains('internal') || spec.contains('general')) {
        keywords.addAll([
          'fever',
          'diabetes',
          'blood pressure',
          'general checkup',
          'common cold',
        ]);
      }
    }

    // Add general medical keywords
    keywords.addAll([
      'medical consultation',
      'health checkup',
      'diagnosis',
      'treatment',
    ]);

    return keywords.toSet().toList(); // Remove duplicates
  }

  /// Generate treatment methods based on specializations
  static List<String> generateTreatmentMethods(DoctorProfile doctor) {
    final methods = <String>[];

    for (final specialization in doctor.specializations) {
      final spec = specialization.toLowerCase();

      if (spec.contains('surgery') || spec.contains('surgical')) {
        methods.addAll([
          'surgical treatment',
          'minimally invasive surgery',
          'post-operative care',
        ]);
      } else if (spec.contains('cardio')) {
        methods.addAll([
          'cardiac catheterization',
          'echocardiography',
          'stress testing',
        ]);
      } else if (spec.contains('ortho')) {
        methods.addAll([
          'joint replacement',
          'arthroscopy',
          'physical therapy',
          'fracture treatment',
        ]);
      } else if (spec.contains('dermato')) {
        methods.addAll(['topical treatment', 'laser therapy', 'skin biopsy']);
      } else if (spec.contains('neuro')) {
        methods.addAll([
          'neurological examination',
          'EEG',
          'brain imaging',
          'medication management',
        ]);
      }
    }

    // Add general treatment methods
    methods.addAll([
      'medication prescription',
      'lifestyle counseling',
      'follow-up care',
      'diagnostic testing',
    ]);

    return methods.toSet().toList(); // Remove duplicates
  }

  /// Utility to test embedding similarity
  static double testEmbeddingSimilarity(
    List<double> embedding1,
    List<double> embedding2,
  ) {
    if (embedding1.length != embedding2.length) return 0.0;

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;

    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }
}

/// Extension for generating Gaussian random numbers
extension RandomGaussian on Random {
  double nextGaussian() {
    if (_hasSpare) {
      _hasSpare = false;
      return _spare!;
    }

    _hasSpare = true;
    final u = nextDouble();
    final v = nextDouble();
    final mag = sqrt(-2.0 * log(u));
    _spare = mag * cos(2.0 * pi * v);
    return mag * sin(2.0 * pi * v);
  }

  static bool _hasSpare = false;
  static double? _spare;
}
