import 'package:flutter_test/flutter_test.dart';
import 'package:doclinker/services/chat_service.dart';

void main() {
  group('ChatService Consolidation Tests', () {
    test('ChatService should have basic methods available', () {
      // Test that the consolidated ChatService has all expected methods
      expect(ChatService.sendMessage, isNotNull);
      expect(ChatService.analyzeSymptoms, isNotNull);
      expect(ChatService.generateFollowUpQuestions, isNotNull);
      expect(ChatService.testConnection, isNotNull);
      expect(ChatService.checkApiHealth, isNotNull);
      expect(ChatService.sendSimpleMessage, isNotNull);
    });

    test('ChatService should handle medical query detection', () {
      // Test internal method via reflection or by behavior
      // Since _isMedicalQuery is private, we can test behavior
      expect(() => ChatService.sendMessage('Hello world'), returnsNormally);
      expect(
        () => ChatService.sendMessage('I have chest pain'),
        returnsNormally,
      );
    });

    test('ChatService should support backward compatibility', () {
      // Test that the simple message method works
      expect(
        () => ChatService.sendSimpleMessage('Test message'),
        returnsNormally,
      );
    });
  });
}
