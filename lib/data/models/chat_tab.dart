import 'chat_message.dart';

class ChatTab {
  final String id;
  final String? sessionId;
  final String title;
  final List<ChatMessage> messages;
  final bool isThinking;

  const ChatTab({
    required this.id,
    this.sessionId,
    required this.title,
    this.messages = const [],
    this.isThinking = false,
  });

  ChatTab copyWith({
    String? id,
    String? sessionId,
    String? title,
    List<ChatMessage>? messages,
    bool? isThinking,
  }) {
    return ChatTab(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
    );
  }
}
