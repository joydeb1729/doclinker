// Configuration file for API keys and endpoints
class AppConfig {
  // HuggingFace API configuration
  // Get your free API key from: https://huggingface.co/settings/tokens
  static const String huggingFaceApiKey = "'YOUR_HF_API_KEY_HERE'";
  //"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";
  static const String huggingFaceBaseUrl =
      'https://api-inference.huggingface.co';

  // Groq API configuration
  // Get your free API key from: https://console.groq.com/keys
  static const String groqApiKey = 'YOUR_GROQ_API_KEY_HERE';
  //"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";
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';

  // Chat model configurations
  static const String chatModelId = 'gemma2-9b-it'; // Gemma2 model for chat
  static const String medicalModelId =
      'gemma2-9b-it'; // Gemma2 model for medical queries

  // Model configurations
  static const String embeddingModelId =
      'sentence-transformers/all-MiniLM-L6-v2';

  // Embedding dimensions for the model
  static const int embeddingDimensions =
      384; // all-MiniLM-L6-v2 produces 384-dim vectors

  // API Configuration
  static const bool useHuggingFace =
      true; // Set to false to use fallback embeddings
  static const bool useGroq =
      true; // Set to false to use fallback chat responses
  static const int maxRetries = 3;
  static const Duration requestTimeout = Duration(seconds: 30);

  // Chat configuration
  static const int maxTokens = 2048;
  static const double temperature = 0.7;
  static const int maxChatHistory = 20; // Maximum messages to keep in context
}
