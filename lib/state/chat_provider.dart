import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/connection_status.dart';
import '../core/network/json_rpc_message.dart';
import '../data/models/chat_message.dart';
import 'connection_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isThinking;
  final String? activeSessionId;

  const ChatState({
    this.messages = const [],
    this.isThinking = false,
    this.activeSessionId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isThinking,
    String? activeSessionId,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isThinking: isThinking ?? this.isThinking,
      activeSessionId: activeSessionId ?? this.activeSessionId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  StreamSubscription? _notificationSub;

  ChatNotifier(this._ref)
      : super(ChatState(
          messages: [
            ChatMessage(
              id: 'init_welcome',
              role: MessageRole.system,
              content:
                  'Talaria remote client ready. Connect to hermes serve daemon to initiate agent sessions.',
              timestamp: DateTime.now(),
            ),
          ],
        )) {
    _listenToNotifications();
  }

  void _listenToNotifications() {
    final connectionNotifier = _ref.read(connectionProvider.notifier);
    _notificationSub = connectionNotifier.notificationStream.listen(_handleServerEvent);
  }

  void _handleServerEvent(JsonRpcNotification notification) {
    switch (notification.method) {
      case 'token.stream':
      case 'prompt.token':
        final token = notification.params?['token'] as String? ?? '';
        _appendStreamingToken(token);
        break;

      case 'token.thought':
      case 'prompt.thought':
        final thought = notification.params?['thought'] as String? ?? '';
        _appendThinkingToken(thought);
        break;

      case 'prompt.done':
      case 'turn.finish':
        _finalizeStreaming();
        break;

      default:
        break;
    }
  }

  void _appendStreamingToken(String token) {
    if (state.messages.isEmpty) return;
    final lastMsg = state.messages.last;

    if (lastMsg.role == MessageRole.assistant && lastMsg.isStreaming) {
      final updated = lastMsg.copyWith(
        content: lastMsg.content + token,
      );
      state = state.copyWith(
        messages: [
          ...state.messages.sublist(0, state.messages.length - 1),
          updated,
        ],
      );
    } else {
      // Start a new assistant message
      final newMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: token,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      state = state.copyWith(
        messages: [...state.messages, newMsg],
      );
    }
  }

  void _appendThinkingToken(String thought) {
    if (state.messages.isEmpty) return;
    final lastMsg = state.messages.last;

    if (lastMsg.role == MessageRole.assistant && lastMsg.isStreaming) {
      final updated = lastMsg.copyWith(
        thought: (lastMsg.thought ?? '') + thought,
      );
      state = state.copyWith(
        messages: [
          ...state.messages.sublist(0, state.messages.length - 1),
          updated,
        ],
      );
    }
  }

  void _finalizeStreaming() {
    if (state.messages.isEmpty) return;
    final lastMsg = state.messages.last;

    if (lastMsg.isStreaming) {
      final updated = lastMsg.copyWith(isStreaming: false);
      state = state.copyWith(
        isThinking: false,
        messages: [
          ...state.messages.sublist(0, state.messages.length - 1),
          updated,
        ],
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isThinking: true,
    );

    final conn = _ref.read(connectionProvider);
    if (!conn.status.isConnected) {
      // Fallback offline notification
      final offlineWarning = ChatMessage(
        id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.system,
        content: 'Cannot send message: WebSocket is disconnected (${conn.serverUrl}). Verify hermes serve is active.',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, offlineWarning],
        isThinking: false,
      );
      return;
    }

    try {
      final client = _ref.read(connectionProvider.notifier);
      await client.call('prompt.submit', {
        'prompt': trimmed,
        if (state.activeSessionId != null) 'session_id': state.activeSessionId,
      });
    } catch (e) {
      final errorMsg = ChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.system,
        content: 'RPC Error: $e',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isThinking: false,
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(
      messages: [
        ChatMessage(
          id: 'cleared_init',
          role: MessageRole.system,
          content: 'Session buffer cleared.',
          timestamp: DateTime.now(),
        ),
      ],
      isThinking: false,
    );
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
