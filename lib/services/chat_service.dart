import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // Groq API Configuration
  static const String _groqApiKey =
      "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";
  static const String _groqApiUrl =
      "https://api.groq.com/openai/v1/chat/completions";

  // Available Groq models (gemma2-9b-it is fast and efficient for chat)
  static const String _defaultModel = "gemma2-9b-it";

  /// Sends a message to the Groq AI API and returns the response
  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': _defaultModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are a helpful AI health assistant for DocLinker, a healthcare management app. 
              
Your role is to:
- Provide accurate, helpful health information and guidance
- Help users understand their symptoms and suggest appropriate medical specialties
- Always recommend users consult healthcare professionals for serious concerns
- Be empathetic, informative, and supportive
- Focus on connecting patients with the right doctors based on their symptoms

Important guidelines:
- Never provide specific medical diagnoses
- Always encourage professional medical consultation
- Be clear about limitations of AI advice
- Prioritize user safety and well-being''',
            },
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
          'top_p': 1,
          'stream': false,
          'stop': null,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        return content ?? 'Sorry, I couldn\'t generate a response.';
      } else {
        print('Groq API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to local response if API fails
      print('Groq API Error: $e');
      return _getFallbackResponse(message);
    }
  }

  /// Provides fallback responses when API is unavailable
  static String _getFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();

    // Emergency symptoms - require immediate attention
    if (lowerMessage.contains('chest pain') ||
        lowerMessage.contains('heart attack') ||
        lowerMessage.contains('difficulty breathing') ||
        lowerMessage.contains('severe bleeding')) {
      return '⚠️ **EMERGENCY**: For severe chest pain, difficulty breathing, or other emergency symptoms, please call emergency services immediately or go to the nearest emergency room. Your safety is our priority.';
    }
    // Common symptoms with specialist recommendations
    else if (lowerMessage.contains('headache') ||
        lowerMessage.contains('head pain') ||
        lowerMessage.contains('migraine')) {
      return 'I understand you\'re experiencing headache symptoms. For persistent or severe headaches, I recommend consulting with:\n• **General Physician** for initial evaluation\n• **Neurologist** for chronic or severe headaches\n\nCommon causes include tension, dehydration, stress, or sinus issues. Keep track of triggers and patterns.';
    } else if (lowerMessage.contains('fever') ||
        lowerMessage.contains('temperature') ||
        lowerMessage.contains('hot')) {
      return 'Fever can indicate various conditions. **Seek medical attention if**:\n• Temperature above 101°F (38.3°C)\n• Fever persists more than 3 days\n• Accompanied by severe symptoms\n\n**Immediate care**: Stay hydrated, rest, and monitor your temperature. Consider seeing a **General Physician** or **Internal Medicine** doctor.';
    } else if (lowerMessage.contains('stomach') ||
        lowerMessage.contains('nausea') ||
        lowerMessage.contains('digestive')) {
      return 'For stomach and digestive issues, consider consulting:\n• **Gastroenterologist** for persistent problems\n• **General Physician** for initial evaluation\n\nCommon causes include diet, stress, infections, or underlying conditions. Monitor symptoms and stay hydrated.';
    } else if (lowerMessage.contains('skin') ||
        lowerMessage.contains('rash') ||
        lowerMessage.contains('itchy')) {
      return 'For skin concerns, I recommend consulting a **Dermatologist**. They specialize in:\n• Skin conditions and rashes\n• Allergic reactions\n• Chronic skin issues\n\nIf symptoms are severe or spreading rapidly, seek prompt medical attention.';
    } else if (lowerMessage.contains('mental health') ||
        lowerMessage.contains('depression') ||
        lowerMessage.contains('anxiety') ||
        lowerMessage.contains('stress')) {
      return 'Mental health is just as important as physical health. Consider consulting:\n• **Psychiatrist** for medication management\n• **Psychologist** for therapy\n• **Counselor** for support\n\nIf you\'re having thoughts of self-harm, please contact a crisis hotline or emergency services immediately.';
    } else if (lowerMessage.contains('health tips') ||
        lowerMessage.contains('advice') ||
        lowerMessage.contains('wellness')) {
      return '🌟 **Health & Wellness Tips**:\n• Stay hydrated (8 glasses of water daily)\n• Exercise regularly (150 minutes/week)\n• Eat a balanced diet with fruits & vegetables\n• Get 7-9 hours of quality sleep\n• Manage stress through meditation or hobbies\n• Schedule regular check-ups\n• Avoid smoking and limit alcohol';
    } else if (lowerMessage.contains('doclinker') ||
        lowerMessage.contains('about') ||
        lowerMessage.contains('app')) {
      return '🏥 **About DocLinker**:\nDocLinker is an AI-powered healthcare platform that connects patients with the right doctors based on their symptoms and medical needs. We help you:\n• Find appropriate medical specialists\n• Understand your symptoms\n• Get healthcare guidance\n• Connect with verified healthcare providers';
    } else if (lowerMessage.contains('doctor') ||
        lowerMessage.contains('specialist')) {
      return 'I can help you find the right doctor! Please describe your symptoms, and I\'ll recommend the appropriate medical specialty:\n• **General Physician** - Overall health\n• **Cardiologist** - Heart conditions\n• **Dermatologist** - Skin issues\n• **Neurologist** - Brain/nerve problems\n• **Orthopedist** - Bone/joint issues\n\nWhat symptoms are you experiencing?';
    } else {
      return '👋 I\'m here to help with your health questions and connect you with the right medical specialists.\n\n**I can help you with**:\n• Understanding symptoms\n• Finding appropriate doctors\n• General health guidance\n• Emergency recognition\n\nPlease describe your symptoms or health concerns, and I\'ll provide guidance on the best medical specialty to consult.';
    }
  }

  /// Sends a message to Groq API with streaming response (for future implementation)
  static Future<Stream<String>> sendMessageStream(String message) async {
    // This is a placeholder for streaming implementation
    // Groq API supports streaming, but requires SSE handling which is more complex
    // For now, we'll use the regular sendMessage method
    throw UnimplementedError('Streaming not yet implemented');
  }

  /// Tests the Groq API connection with a simple query
  static Future<String> testConnection() async {
    try {
      return await sendMessage(
        "Hello, please confirm you're working correctly.",
      );
    } catch (e) {
      return "Connection test failed: $e";
    }
  }

  /// Checks if the Groq API is available
  static Future<bool> checkApiHealth() async {
    try {
      // Test with a simple message to check API availability
      final response = await http.post(
        Uri.parse(_groqApiUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': _defaultModel,
          'messages': [
            {'role': 'user', 'content': 'Hello'},
          ],
          'temperature': 0.1,
          'max_tokens': 10,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Groq API Health Check Error: $e');
      return false;
    }
  }
}
