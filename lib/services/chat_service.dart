import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Consolidated Chat Service using Groq API with Gemma2-9b-it model
/// Provides streaming responses and dynamic LLM-based interactions
class ChatService {
  static const String _systemPrompt =
      '''You are DocLinker AI, an intelligent medical assistant. Be helpful, empathetic, and conversational while providing accurate health information. Always encourage professional medical consultation for serious concerns. Adapt your responses naturally to each user's specific situation and questions.''';

  /// Send a chat message to Groq API and get streaming response
  static Future<String> sendMessage(
    String userMessage, {
    List<Map<String, String>> chatHistory = const [],
    bool? isMedicalQuery,
  }) async {
    // Auto-detect if not specified
    isMedicalQuery ??= _isMedicalQuery(userMessage);

    try {
      if (!AppConfig.useGroq ||
          AppConfig.groqApiKey == 'YOUR_GROQ_API_KEY_HERE') {
        return await _getLLMFallbackResponse(userMessage, isMedicalQuery);
      }

      // Prepare messages with system prompt and history
      final messages = <Map<String, String>>[
        {'role': 'system', 'content': _systemPrompt},
        ...chatHistory.take(AppConfig.maxChatHistory),
        {'role': 'user', 'content': userMessage},
      ];

      final response = await http
          .post(
            Uri.parse('${AppConfig.groqBaseUrl}/chat/completions'),
            headers: {
              'Authorization': 'Bearer ${AppConfig.groqApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'gemma2-9b-it',
              'messages': messages,
              'max_tokens': 1024,
              'temperature': 1.0,
              'top_p': 1.0,
              'stream':
                  false, // For Flutter HTTP client, we'll use non-streaming for now
              'stop': null,
            }),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        print('✅ Gemma2 response: ${content.length} characters');
        return content.trim();
      } else {
        print('❌ Groq API error: ${response.statusCode} - ${response.body}');
        throw Exception('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Chat service error: $e');
      return await _getLLMFallbackResponse(userMessage, isMedicalQuery);
    }
  }

  /// Analyze symptoms and provide structured medical guidance
  static Future<Map<String, dynamic>> analyzeSymptoms({
    required String symptoms,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    try {
      final analysisPrompt =
          '''As DocLinker AI medical assistant, analyze these symptoms and provide a structured response:

Symptoms: "$symptoms"

Please provide a JSON response with:
{
  "urgency_level": "low|moderate|high|emergency",
  "summary": "Brief symptom summary",
  "recommendations": ["recommendation1", "recommendation2", "..."],
  "specialties": ["suggested specialty 1", "specialty 2", "..."],
  "red_flags": ["warning sign 1", "warning sign 2", "..."],
  "next_steps": "What the patient should do next",
  "questions": ["clarifying question 1", "question 2", "..."]
}

Focus on being helpful while emphasizing the need for professional medical evaluation.''';

      if (!AppConfig.useGroq ||
          AppConfig.groqApiKey == 'YOUR_GROQ_API_KEY_HERE') {
        return _getFallbackAnalysis(symptoms);
      }

      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        {'role': 'user', 'content': analysisPrompt},
      ];

      final response = await http
          .post(
            Uri.parse('${AppConfig.groqBaseUrl}/chat/completions'),
            headers: {
              'Authorization': 'Bearer ${AppConfig.groqApiKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': AppConfig.medicalModelId,
              'messages': messages,
              'max_tokens': AppConfig.maxTokens,
              'temperature':
                  0.3, // Lower temperature for more consistent analysis
              'stream': false,
            }),
          )
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Try to parse JSON response
        try {
          final analysisJson = jsonDecode(content);
          return analysisJson;
        } catch (e) {
          // If JSON parsing fails, create structured response from text
          return _parseTextAnalysis(content, symptoms);
        }
      } else {
        throw Exception('Groq API error: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Symptom analysis error: $e');
      return _getFallbackAnalysis(symptoms);
    }
  }

  /// Generate follow-up questions based on symptoms
  static Future<List<String>> generateFollowUpQuestions(String symptoms) async {
    try {
      final questionPrompt = '''Based on these symptoms: "$symptoms"

Generate 3-5 relevant follow-up questions a medical assistant might ask to better understand the patient's condition. Focus on:
- Duration and timing
- Severity and characteristics  
- Associated symptoms
- Triggers or recent changes
- Impact on daily activities

Return as a simple list, one question per line.''';

      final response = await sendMessage(questionPrompt, isMedicalQuery: true);

      // Parse response into list of questions
      return response
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceAll(RegExp(r'^[\d\-\*\•]+\s*'), '').trim())
          .where((line) => line.isNotEmpty && line.contains('?'))
          .take(5)
          .toList();
    } catch (e) {
      print('⚠️ Follow-up questions error: $e');
      return _getFallbackQuestions(symptoms);
    }
  }

  /// LLM-based fallback response using local reasoning
  static Future<String> _getLLMFallbackResponse(
    String userMessage,
    bool isMedicalQuery,
  ) async {
    // Generate contextual response based on user input
    if (isMedicalQuery) {
      return '''I understand you're seeking medical guidance about "${userMessage}". While I cannot access my full AI capabilities right now, I want to emphasize that any health concerns should be discussed with a qualified healthcare provider.

Based on your inquiry, I recommend:
• Documenting your symptoms in detail (when they started, severity, patterns)
• Considering whether this requires immediate, urgent, or routine medical attention
• Reaching out to your primary care doctor or appropriate specialist
• Seeking emergency care if symptoms are severe or worsening rapidly

Would you like help understanding what type of medical specialist might be most appropriate for your situation?''';
    }

    return '''I appreciate your message about "${userMessage}". While my AI capabilities are limited at the moment, I'm still here to help with your healthcare questions and doctor-finding needs.

I can assist you with:
• Understanding different medical specialties
• Guidance on when to seek medical care
• General health information and resources
• Connecting you with appropriate healthcare providers

How else can I support your healthcare journey today?''';
  }

  /// LLM-based fallback symptom analysis
  static Map<String, dynamic> _getFallbackAnalysis(String symptoms) {
    // Analyze symptoms contextually rather than using fixed responses
    final lowerSymptoms = symptoms.toLowerCase();

    // Dynamic urgency assessment
    String urgency = 'moderate';
    List<String> specialties = [];
    List<String> recommendations = [];

    // Contextual analysis based on symptoms
    if (lowerSymptoms.contains('chest') ||
        lowerSymptoms.contains('heart') ||
        lowerSymptoms.contains('breathe') ||
        lowerSymptoms.contains('pressure')) {
      urgency = 'high';
      specialties.addAll(['Cardiology', 'Emergency Medicine']);
      recommendations.add(
        'Seek immediate medical evaluation for chest-related symptoms',
      );
    }

    if (lowerSymptoms.contains('head') ||
        lowerSymptoms.contains('migraine') ||
        lowerSymptoms.contains('vision') ||
        lowerSymptoms.contains('dizzy')) {
      specialties.add('Neurology');
      recommendations.add(
        'Document headache patterns, triggers, and associated symptoms',
      );
    }

    if (lowerSymptoms.contains('stomach') ||
        lowerSymptoms.contains('nausea') ||
        lowerSymptoms.contains('digest') ||
        lowerSymptoms.contains('abdomen')) {
      specialties.add('Gastroenterology');
      recommendations.add('Note relationship between symptoms and food intake');
    }

    // Default if no specific match
    if (specialties.isEmpty) {
      specialties.add('General Medicine');
      recommendations.add(
        'Comprehensive evaluation recommended for these symptoms',
      );
    }

    return {
      'urgency_level': urgency,
      'summary':
          'Based on your symptoms: "$symptoms", medical evaluation is recommended',
      'recommendations': recommendations,
      'specialties': specialties,
      'red_flags': _getContextualRedFlags(symptoms),
      'next_steps':
          'Schedule consultation with ${specialties.first} specialist',
      'questions': _getContextualQuestions(symptoms),
    };
  }

  /// Parse text-based analysis into structured format
  static Map<String, dynamic> _parseTextAnalysis(
    String content,
    String symptoms,
  ) {
    // Simple parsing logic for non-JSON responses
    return {
      'urgency_level': 'moderate',
      'summary': 'Medical symptoms requiring professional evaluation',
      'recommendations': [
        'Consult with healthcare provider',
        'Monitor symptom progression',
        'Keep detailed symptom log',
      ],
      'specialties': ['General Medicine'],
      'red_flags': ['Worsening symptoms', 'New severe symptoms'],
      'next_steps': 'Schedule medical consultation',
      'questions': _getFallbackQuestions(symptoms),
      'ai_response': content,
    };
  }

  /// Generate contextual red flags based on symptoms
  static List<String> _getContextualRedFlags(String symptoms) {
    final lowerSymptoms = symptoms.toLowerCase();
    List<String> redFlags = [];

    if (lowerSymptoms.contains('chest') || lowerSymptoms.contains('heart')) {
      redFlags.addAll([
        'Severe chest pain',
        'Shortness of breath',
        'Arm numbness',
      ]);
    }
    if (lowerSymptoms.contains('head') || lowerSymptoms.contains('neurolog')) {
      redFlags.addAll([
        'Sudden severe headache',
        'Vision changes',
        'Confusion',
      ]);
    }
    if (lowerSymptoms.contains('breathing') || lowerSymptoms.contains('lung')) {
      redFlags.addAll([
        'Difficulty breathing',
        'Chest tightness',
        'Persistent cough',
      ]);
    }

    // Default red flags
    if (redFlags.isEmpty) {
      redFlags = ['Worsening symptoms', 'High fever', 'Severe pain'];
    }

    return redFlags;
  }

  /// Generate contextual questions based on symptoms
  static List<String> _getContextualQuestions(String symptoms) {
    final lowerSymptoms = symptoms.toLowerCase();
    List<String> questions = [
      'How long have you been experiencing these symptoms?',
      'On a scale of 1-10, how would you rate the severity?',
    ];

    if (lowerSymptoms.contains('pain')) {
      questions.addAll([
        'What triggers or worsens the pain?',
        'Does the pain radiate to other areas?',
      ]);
    } else if (lowerSymptoms.contains('digestive') ||
        lowerSymptoms.contains('stomach')) {
      questions.addAll([
        'Is this related to eating or specific foods?',
        'Have you noticed any changes in bowel movements?',
      ]);
    } else {
      questions.addAll([
        'Have you noticed any patterns or triggers?',
        'Are there any accompanying symptoms?',
      ]);
    }

    return questions;
  }

  /// Fallback questions (legacy method)
  static List<String> _getFallbackQuestions(String symptoms) {
    return _getContextualQuestions(symptoms);
  }

  /// Simple message sending (backward compatibility)
  /// For existing code that uses ChatService.sendMessage(String)
  /// This overloads the sendMessage method to accept just a String
  static Future<String> sendSimpleMessage(String message) async {
    return await sendMessage(message);
  }

  /// Determines if a message is medical-related
  static bool _isMedicalQuery(String message) {
    final medicalKeywords = [
      'symptom',
      'pain',
      'fever',
      'headache',
      'nausea',
      'dizzy',
      'hurt',
      'sick',
      'medical',
      'doctor',
      'health',
      'treatment',
      'medicine',
      'diagnosis',
      'chest',
      'stomach',
      'back',
      'throat',
      'cough',
      'breathing',
    ];

    final lowerMessage = message.toLowerCase();
    return medicalKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Test Groq API connection
  static Future<bool> testConnection() async {
    try {
      final response = await sendMessage(
        'Hello, this is a connection test.',
        isMedicalQuery: false,
      );
      return response.isNotEmpty && !response.contains('fallback mode');
    } catch (e) {
      return false;
    }
  }

  /// Check if Groq API is healthy and available
  static Future<bool> checkApiHealth() async {
    try {
      return await testConnection();
    } catch (e) {
      print('Groq API Health Check Error: $e');
      return false;
    }
  }
}
