import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/chat_service.dart';
import '../services/embedding_service.dart';

class ApiConfigTestPage extends StatefulWidget {
  const ApiConfigTestPage({super.key});

  @override
  State<ApiConfigTestPage> createState() => _ApiConfigTestPageState();
}

class _ApiConfigTestPageState extends State<ApiConfigTestPage> {
  bool _isTestingGroq = false;
  bool _isTestingHuggingFace = false;
  String _groqResult = '';
  String _huggingFaceResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Configuration Test'),
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
                      'API Configuration Status',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Groq API Status
                    Row(
                      children: [
                        Icon(
                          AppConfig.groqApiKey != 'YOUR_GROQ_API_KEY_HERE'
                              ? Icons.check_circle
                              : Icons.warning,
                          color:
                              AppConfig.groqApiKey != 'YOUR_GROQ_API_KEY_HERE'
                              ? Colors.green
                              : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Groq API Key: ${AppConfig.groqApiKey != 'YOUR_GROQ_API_KEY_HERE' ? 'Configured' : 'Not Configured'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color:
                                      AppConfig.groqApiKey !=
                                          'YOUR_GROQ_API_KEY_HERE'
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // HuggingFace API Status
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
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'HuggingFace API Key: ${AppConfig.huggingFaceApiKey != 'YOUR_HF_API_KEY_HERE' ? 'Configured' : 'Not Configured'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color:
                                      AppConfig.huggingFaceApiKey !=
                                          'YOUR_HF_API_KEY_HERE'
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Models: ${AppConfig.chatModelId} (Chat), ${AppConfig.embeddingModelId} (Embeddings)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Groq Chat Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chat, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Groq Chat API Test',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isTestingGroq ? null : _testGroqApi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                        child: _isTestingGroq
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Testing Groq API...'),
                                ],
                              )
                            : const Text('Test Groq Chat API'),
                      ),
                    ),
                    if (_groqResult.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _groqResult.contains('✅')
                              ? Colors.green[50]
                              : Colors.red[50],
                          border: Border.all(
                            color: _groqResult.contains('✅')
                                ? Colors.green
                                : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _groqResult,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _groqResult.contains('✅')
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // HuggingFace Embedding Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.scatter_plot, color: Colors.purple[600]),
                        const SizedBox(width: 8),
                        Text(
                          'HuggingFace Embedding API Test',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isTestingHuggingFace
                            ? null
                            : _testHuggingFaceApi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                        ),
                        child: _isTestingHuggingFace
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Testing HuggingFace API...'),
                                ],
                              )
                            : const Text('Test HuggingFace Embedding API'),
                      ),
                    ),
                    if (_huggingFaceResult.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _huggingFaceResult.contains('✅')
                              ? Colors.green[50]
                              : Colors.red[50],
                          border: Border.all(
                            color: _huggingFaceResult.contains('✅')
                                ? Colors.green
                                : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _huggingFaceResult,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _huggingFaceResult.contains('✅')
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

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
                          'Setup Instructions',
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
                      '1. Get Groq API key from: console.groq.com/keys\n'
                      '2. Get HuggingFace API key from: huggingface.co/settings/tokens\n'
                      '3. Add both keys to lib/config/app_config.dart\n'
                      '4. Test both APIs using the buttons above',
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

  Future<void> _testGroqApi() async {
    setState(() {
      _isTestingGroq = true;
      _groqResult = '';
    });

    try {
      final startTime = DateTime.now();

      final response = await ChatService.sendMessage(
        'Hello, this is a test message. Please respond briefly.',
        isMedicalQuery: false,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      setState(() {
        _groqResult =
            '''✅ Groq API Test Successful!

Response: "${response.length > 100 ? '${response.substring(0, 100)}...' : response}"

⏱️ Response time: ${duration.inMilliseconds}ms
🤖 Model: ${AppConfig.chatModelId}
🔑 API Key: ${AppConfig.groqApiKey.substring(0, 8)}...''';
        _isTestingGroq = false;
      });
    } catch (e) {
      setState(() {
        _groqResult =
            '''❌ Groq API Test Failed

Error: $e

💡 Check your API key in app_config.dart
🔗 Get API key: console.groq.com/keys''';
        _isTestingGroq = false;
      });
    }
  }

  Future<void> _testHuggingFaceApi() async {
    setState(() {
      _isTestingHuggingFace = true;
      _huggingFaceResult = '';
    });

    try {
      final startTime = DateTime.now();

      final embedding = await EmbeddingService.generateSymptomEmbedding(
        'Test message for embedding generation',
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      setState(() {
        _huggingFaceResult =
            '''✅ HuggingFace API Test Successful!

📊 Embedding generated: ${embedding.length} dimensions
⏱️ Response time: ${duration.inMilliseconds}ms  
🤖 Model: ${AppConfig.embeddingModelId}
🔑 API Key: ${AppConfig.huggingFaceApiKey.substring(0, 8)}...

Vector sample: [${embedding.take(3).map((v) => v.toStringAsFixed(3)).join(', ')}...]''';
        _isTestingHuggingFace = false;
      });
    } catch (e) {
      setState(() {
        _huggingFaceResult =
            '''❌ HuggingFace API Test Failed

Error: $e

💡 Check your API key in app_config.dart
🔗 Get API key: huggingface.co/settings/tokens''';
        _isTestingHuggingFace = false;
      });
    }
  }
}
