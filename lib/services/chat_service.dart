import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  // Use 10.0.2.2 for Android emulator, localhost for web/desktop
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// Sends a message to the AI chat API and returns the response
  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'] ?? 'Sorry, I couldn\'t generate a response.';
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to local response if API fails
      print('API Error: $e');
      return _getFallbackResponse(message);
    }
  }

  /// Provides fallback responses when API is unavailable
  static String _getFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('headache') ||
        lowerMessage.contains('head pain')) {
      return 'I understand you\'re experiencing headache symptoms. For persistent headaches, I recommend consulting with a neurologist or general physician. Common causes include tension, dehydration, or stress.';
    } else if (lowerMessage.contains('fever') ||
        lowerMessage.contains('temperature')) {
      return 'Fever can indicate various conditions. If your temperature is above 101°F (38.3°C) or persists, please consult a healthcare provider. Stay hydrated and rest.';
    } else if (lowerMessage.contains('chest pain') ||
        lowerMessage.contains('heart')) {
      return 'Chest pain requires immediate medical attention. Please contact emergency services or visit the nearest emergency room if you\'re experiencing severe chest pain.';
    } else if (lowerMessage.contains('health tips') ||
        lowerMessage.contains('advice')) {
      return 'Here are some health tips:\\n• Stay hydrated\\n• Exercise regularly\\n• Eat a balanced diet\\n• Get adequate sleep\\n• Manage stress';
    } else if (lowerMessage.contains('doclinker') ||
        lowerMessage.contains('about')) {
      return 'DocLinker is an AI-powered healthcare platform that connects patients with the right doctors based on their symptoms and medical needs.';
    } else {
      return 'I\'m here to help with your health questions. Could you please provide more details about your symptoms or health concerns?';
    }
  }

  /// Checks if the API is available
  static Future<bool> checkApiHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
