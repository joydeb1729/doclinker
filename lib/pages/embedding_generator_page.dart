import 'package:flutter/material.dart';
import '../services/embedding_service.dart';
import '../models/doctor_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmbeddingGeneratorPage extends StatefulWidget {
  const EmbeddingGeneratorPage({super.key});

  @override
  State<EmbeddingGeneratorPage> createState() => _EmbeddingGeneratorPageState();
}

class _EmbeddingGeneratorPageState extends State<EmbeddingGeneratorPage> {
  bool _isGenerating = false;
  String _status = '';
  int _totalDoctors = 0;
  int _processedDoctors = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Embedding Generator'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RAG Embedding Generator',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This utility generates vector embeddings for all doctor profiles in Firestore, enabling RAG-based symptom matching.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'What this does:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Fetches all verified doctor profiles'),
                    const Text(
                      '• Generates vector embeddings from specializations & expertise',
                    ),
                    const Text(
                      '• Adds expertise keywords and treatment methods',
                    ),
                    const Text('• Updates Firestore with embedding data'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_totalDoctors > 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: $_processedDoctors / $_totalDoctors doctors',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _totalDoctors > 0
                            ? _processedDoctors / _totalDoctors
                            : 0,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue[600]!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_status.isNotEmpty) ...[
              Card(
                color: _status.contains('Error')
                    ? Colors.red[50]
                    : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _status.contains('Error')
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('Error')
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateEmbeddings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isGenerating
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Generating Embeddings...'),
                        ],
                      )
                    : const Text('Generate Embeddings for All Doctors'),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isGenerating ? null : _testEmbeddings,
                child: const Text('Test Embedding Similarity'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateEmbeddings() async {
    setState(() {
      _isGenerating = true;
      _status = 'Starting embedding generation...';
      _totalDoctors = 0;
      _processedDoctors = 0;
    });

    try {
      // First, get the count of doctors
      final doctorsSnapshot = await FirebaseFirestore.instance
          .collection('doctor_profiles')
          .where('isVerified', isEqualTo: true)
          .get();

      setState(() {
        _totalDoctors = doctorsSnapshot.docs.length;
        _status = 'Found $_totalDoctors verified doctors. Processing...';
      });

      // Process each doctor with progress updates
      for (int i = 0; i < doctorsSnapshot.docs.length; i++) {
        final doc = doctorsSnapshot.docs[i];

        try {
          final doctor = DoctorProfile.fromFirestore(doc);

          // Skip if embedding already exists
          if (doctor.profileEmbedding != null &&
              doctor.profileEmbedding!.isNotEmpty) {
            setState(() {
              _processedDoctors = i + 1;
              _status = 'Skipping ${doctor.fullName} - embedding exists';
            });
            continue;
          }

          setState(() {
            _status = 'Generating embedding for ${doctor.fullName}...';
          });

          // Generate embedding
          final embedding = await EmbeddingService.generateDoctorEmbedding(
            doctor,
          );

          // Generate expertise keywords and treatment methods if not present
          final expertiseKeywords =
              doctor.expertiseKeywords ??
              EmbeddingService.generateExpertiseKeywords(doctor);
          final treatmentMethods =
              doctor.treatmentMethods ??
              EmbeddingService.generateTreatmentMethods(doctor);

          // Update doctor profile
          await doc.reference.update({
            'profileEmbedding': embedding,
            'expertiseKeywords': expertiseKeywords,
            'treatmentMethods': treatmentMethods,
            'embeddingGeneratedAt': FieldValue.serverTimestamp(),
          });

          setState(() {
            _processedDoctors = i + 1;
            _status =
                'Updated ${doctor.fullName} (${_processedDoctors}/$_totalDoctors)';
          });

          // Small delay to avoid overwhelming the API
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          setState(() {
            _status = 'Error processing doctor ${doc.id}: $e';
          });
          continue;
        }
      }

      setState(() {
        _status =
            '🎉 Successfully generated embeddings for $_processedDoctors doctors!';
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isGenerating = false;
      });
    }
  }

  Future<void> _testEmbeddings() async {
    setState(() {
      _status = 'Testing embedding similarity...';
    });

    try {
      // Get two doctors with embeddings
      final doctorsSnapshot = await FirebaseFirestore.instance
          .collection('doctor_profiles')
          .where('profileEmbedding', isNull: false)
          .limit(2)
          .get();

      if (doctorsSnapshot.docs.length < 2) {
        setState(() {
          _status =
              'Need at least 2 doctors with embeddings to test similarity';
        });
        return;
      }

      final doctor1 = DoctorProfile.fromFirestore(doctorsSnapshot.docs[0]);
      final doctor2 = DoctorProfile.fromFirestore(doctorsSnapshot.docs[1]);

      if (doctor1.profileEmbedding == null ||
          doctor2.profileEmbedding == null) {
        setState(() {
          _status = 'Doctor embeddings are null';
        });
        return;
      }

      final similarity = EmbeddingService.testEmbeddingSimilarity(
        doctor1.profileEmbedding!,
        doctor2.profileEmbedding!,
      );

      setState(() {
        _status =
            '''Test Results:
Doctor 1: ${doctor1.fullName} (${doctor1.specializations.join(', ')})
Doctor 2: ${doctor2.fullName} (${doctor2.specializations.join(', ')})
Similarity Score: ${similarity.toStringAsFixed(3)}

${similarity > 0.7
                ? 'High similarity'
                : similarity > 0.4
                ? 'Moderate similarity'
                : 'Low similarity'}''';
      });
    } catch (e) {
      setState(() {
        _status = 'Error testing embeddings: $e';
      });
    }
  }
}
