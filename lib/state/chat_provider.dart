import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/connection_status.dart';
import '../core/network/json_rpc_message.dart';
import '../data/models/chat_message.dart';
import '../data/models/tool_call.dart';
import 'connection_provider.dart';
import 'project_provider.dart';
import 'session_provider.dart';

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

      case 'tool.start':
      case 'tool.call':
        if (notification.params is Map<String, dynamic>) {
          final toolCall = ToolCall.fromJson(notification.params as Map<String, dynamic>);
          _onToolStarted(toolCall);
        }
        break;

      case 'tool.output':
      case 'tool.stream':
        final toolId = notification.params?['id'] as String? ?? '';
        final output = notification.params?['output'] as String? ?? '';
        _onToolOutput(toolId, output);
        break;

      case 'tool.done':
      case 'tool.finish':
        final toolId = notification.params?['id'] as String? ?? '';
        final statusStr = notification.params?['status'] as String? ?? 'done';
        final duration = notification.params?['duration_ms'] as int?;
        _onToolFinished(toolId, statusStr, duration);
        break;

      case 'prompt.done':
      case 'turn.finish':
        _finalizeStreaming();
        break;

      default:
        break;
    }
  }

  void _onToolStarted(ToolCall tool) {
    _ensureStreamingAssistantMessage();
    final lastMsg = state.messages.last;
    final updatedTools = [...lastMsg.toolCalls, tool];
    final updatedMsg = lastMsg.copyWith(toolCalls: updatedTools);

    state = state.copyWith(
      messages: [
        ...state.messages.sublist(0, state.messages.length - 1),
        updatedMsg,
      ],
    );
  }

  void _onToolOutput(String toolId, String output) {
    if (state.messages.isEmpty) return;
    final lastMsg = state.messages.last;
    if (lastMsg.role != MessageRole.assistant) return;

    final updatedTools = lastMsg.toolCalls.map((t) {
      if (t.id == toolId || toolId.isEmpty) {
        return t.copyWith(output: (t.output ?? '') + output);
      }
      return t;
    }).toList();

    final updatedMsg = lastMsg.copyWith(toolCalls: updatedTools);
    state = state.copyWith(
      messages: [
        ...state.messages.sublist(0, state.messages.length - 1),
        updatedMsg,
      ],
    );
  }

  void _onToolFinished(String toolId, String statusStr, int? durationMs) {
    if (state.messages.isEmpty) return;
    final lastMsg = state.messages.last;
    if (lastMsg.role != MessageRole.assistant) return;

    final updatedTools = lastMsg.toolCalls.map((t) {
      if (t.id == toolId || toolId.isEmpty) {
        return t.copyWith(
          status: statusStr == 'error' ? ToolExecutionStatus.error : ToolExecutionStatus.done,
          durationMs: durationMs,
        );
      }
      return t;
    }).toList();

    final updatedMsg = lastMsg.copyWith(toolCalls: updatedTools);
    state = state.copyWith(
      messages: [
        ...state.messages.sublist(0, state.messages.length - 1),
        updatedMsg,
      ],
    );
  }

  void _ensureStreamingAssistantMessage() {
    if (state.messages.isEmpty ||
        state.messages.last.role != MessageRole.assistant ||
        !state.messages.last.isStreaming) {
      final newMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      state = state.copyWith(
        messages: [...state.messages, newMsg],
      );
    }
  }

  void _appendStreamingToken(String token) {
    _ensureStreamingAssistantMessage();
    final lastMsg = state.messages.last;

    final updated = lastMsg.copyWith(
      content: lastMsg.content + token,
    );
    state = state.copyWith(
      messages: [
        ...state.messages.sublist(0, state.messages.length - 1),
        updated,
      ],
    );
  }

  void _appendThinkingToken(String thought) {
    _ensureStreamingAssistantMessage();
    final lastMsg = state.messages.last;

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
      final repo = _ref.read(hermesRepositoryProvider);

      // If no active session, automatically create a new session
      String? sessionId = state.activeSessionId;
      if (sessionId == null || sessionId.isEmpty) {
        final activeProject = _ref.read(projectProvider).activeProject;
        final title = trimmed.length > 40 ? '${trimmed.substring(0, 40)}...' : trimmed;
        final newSession = await repo.createSession(
          title: title,
          cwd: activeProject?.path,
          project: activeProject?.name,
        );
        sessionId = newSession.id;
        state = state.copyWith(activeSessionId: sessionId);
        _ref.read(sessionProvider.notifier).addSession(newSession);
      }

      await repo.submitPrompt(trimmed, sessionId: sessionId);
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

  void loadResumedSession(String sessionId, List<dynamic> rawMessages) {
    final List<ChatMessage> parsed = [];
    for (final raw in rawMessages) {
      if (raw is Map) {
        final roleStr = raw['role']?.toString().toLowerCase() ?? 'user';
        final role = roleStr == 'assistant'
            ? MessageRole.assistant
            : (roleStr == 'system' ? MessageRole.system : MessageRole.user);
        final content = raw['content']?.toString() ?? raw['text']?.toString() ?? '';
        final thought = raw['thought']?.toString() ?? raw['reasoning']?.toString();

        DateTime parseTs(dynamic val) {
          if (val is num) {
            return DateTime.fromMillisecondsSinceEpoch((val * 1000).toInt());
          }
          if (val != null) {
            return DateTime.tryParse(val.toString()) ?? DateTime.now();
          }
          return DateTime.now();
        }

        parsed.add(ChatMessage(
          id: raw['row_id']?.toString() ??
              raw['id']?.toString() ??
              'msg_${DateTime.now().microsecondsSinceEpoch}',
          role: role,
          content: content,
          thought: thought,
          timestamp: parseTs(raw['timestamp']),
        ));
      }
    }

    state = state.copyWith(
      activeSessionId: sessionId,
      messages: parsed.isNotEmpty
          ? parsed
          : [
              ChatMessage(
                id: 'resumed_empty',
                role: MessageRole.system,
                content: 'Resumed session $sessionId.',
                timestamp: DateTime.now(),
              ),
            ],
      isThinking: false,
    );
  }

  void startNewSession() {
    state = state.copyWith(
      activeSessionId: null,
      messages: [
        ChatMessage(
          id: 'new_session_init',
          role: MessageRole.system,
          content: 'New session started. Send a prompt to begin.',
          timestamp: DateTime.now(),
        ),
      ],
      isThinking: false,
    );
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
