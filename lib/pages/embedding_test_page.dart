import 'package:flutter/material.dart';
import '../services/embedding_service.dart';
import '../config/app_config.dart';

class EmbeddingTestPage extends StatefulWidget {
  const EmbeddingTestPage({super.key});

  @override
  State<EmbeddingTestPage> createState() => _EmbeddingTestPageState();
}

class _EmbeddingTestPageState extends State<EmbeddingTestPage> {
  final _textController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HuggingFace Embedding Test'),
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
                      'Test HuggingFace Embeddings',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Model: ${AppConfig.embeddingModelId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Dimensions: ${AppConfig.embeddingDimensions}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          AppConfig.huggingFaceApiKey != 'YOUR_HF_API_KEY_HERE'
                              ? Icons.check_circle
                              : Icons.warning,
                          color:
                              AppConfig.huggingFaceApiKey !=
                                  'YOUR_HF_API_KEY_HERE'
                              ? Colors.green
                              : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppConfig.huggingFaceApiKey != 'YOUR_HF_API_KEY_HERE'
                              ? 'HuggingFace API Key Configured'
                              : 'API Key Not Configured (will use fallback)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color:
                                    AppConfig.huggingFaceApiKey !=
                                        'YOUR_HF_API_KEY_HERE'
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter text to embed',
                hintText: 'e.g., "I have a severe headache and feel dizzy"',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testEmbedding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
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
                          Text('Generating Embedding...'),
                        ],
                      )
                    : const Text('Generate Embedding'),
              ),
            ),
            const SizedBox(height: 20),

            if (_result.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Result',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Text(
                            _result,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Text is sent to HuggingFace ${AppConfig.embeddingModelId}\n'
                      '2. Model returns ${AppConfig.embeddingDimensions}-dimensional vector\n'
                      '3. Vector represents semantic meaning of text\n'
                      '4. Similar texts have similar vectors (high cosine similarity)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testEmbedding() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter some text')));
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final startTime = DateTime.now();

      // Generate embedding using our service
      final embedding = await EmbeddingService.generateSymptomEmbedding(
        _textController.text.trim(),
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Format result
      final resultText =
          '''✅ Embedding Generated Successfully!

📊 Statistics:
• Dimensions: ${embedding.length}
• Processing time: ${duration.inMilliseconds}ms
• API Source: ${AppConfig.huggingFaceApiKey != 'YOUR_HF_API_KEY_HERE' ? 'HuggingFace API' : 'Fallback Generation'}

🔢 Vector (first 10 values):
${embedding.take(10).map((v) => v.toStringAsFixed(6)).join(', ')}...

📈 Vector Statistics:
• Min: ${embedding.reduce((a, b) => a < b ? a : b).toStringAsFixed(6)}
• Max: ${embedding.reduce((a, b) => a > b ? a : b).toStringAsFixed(6)}
• Mean: ${(embedding.reduce((a, b) => a + b) / embedding.length).toStringAsFixed(6)}

💡 This vector can now be used to find similar doctor profiles or symptoms through cosine similarity calculation.''';

      setState(() {
        _result = resultText;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = '❌ Error generating embedding:\n\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
