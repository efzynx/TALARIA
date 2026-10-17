import 'package:flutter_test/flutter_test.dart';
import 'package:talaria/data/models/chat_message.dart';
import 'package:talaria/data/models/chat_tab.dart';

void main() {
  group('ChatTab Model Tests', () {
    test('ChatTab holds independent session and messages state', () {
      final tab1 = ChatTab(
        id: 'tab_1',
        title: 'Main Chat',
        sessionId: 'sess_1',
        messages: [
          ChatMessage(
            id: 'm1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
          ),
        ],
        isThinking: false,
      );

      const tab2 = ChatTab(
        id: 'tab_2',
        title: 'Reverse Engineering',
        sessionId: 'sess_2',
        messages: [],
        isThinking: true,
      );

      expect(tab1.id, 'tab_1');
      expect(tab1.title, 'Main Chat');
      expect(tab1.messages.length, 1);
      expect(tab1.isThinking, isFalse);

      expect(tab2.id, 'tab_2');
      expect(tab2.title, 'Reverse Engineering');
      expect(tab2.messages, isEmpty);
      expect(tab2.isThinking, isTrue);

      final updatedTab1 = tab1.copyWith(isThinking: true);
      expect(updatedTab1.isThinking, isTrue);
      expect(tab1.isThinking, isFalse);
    });
  });
}
