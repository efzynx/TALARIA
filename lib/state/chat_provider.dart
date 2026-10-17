import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/connection_status.dart';
import '../core/network/json_rpc_message.dart';
import '../data/models/chat_message.dart';
import '../data/models/chat_tab.dart';
import '../data/models/tool_call.dart';
import 'connection_provider.dart';
import 'model_provider.dart';
import 'project_provider.dart';
import 'session_provider.dart';
import 'skills_provider.dart';

class ChatState {
  final List<ChatTab> tabs;
  final int activeTabIndex;

  const ChatState({
    required this.tabs,
    this.activeTabIndex = 0,
  });

  ChatTab get activeTab {
    if (activeTabIndex >= 0 && activeTabIndex < tabs.length) {
      return tabs[activeTabIndex];
    }
    return tabs.isNotEmpty
        ? tabs.first
        : const ChatTab(
            id: 'fallback_tab',
            title: 'Chat 1',
            messages: [],
          );
  }

  List<ChatMessage> get messages => activeTab.messages;
  bool get isThinking => activeTab.isThinking;
  String? get activeSessionId => activeTab.sessionId;

  ChatState copyWith({
    List<ChatTab>? tabs,
    int? activeTabIndex,
  }) {
    return ChatState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  StreamSubscription? _notificationSub;
  int _tabCounter = 1;

  ChatNotifier(this._ref)
      : super(ChatState(
          tabs: [
            ChatTab(
              id: 'tab_1',
              title: 'Chat 1',
              messages: [
                ChatMessage(
                  id: 'init_welcome',
                  role: MessageRole.system,
                  content:
                      'Talaria remote client ready. Connect to hermes serve daemon to initiate agent sessions.',
                  timestamp: DateTime.now(),
                ),
              ],
            ),
          ],
          activeTabIndex: 0,
        )) {
    _listenToNotifications();
  }

  void _listenToNotifications() {
    final connectionNotifier = _ref.read(connectionProvider.notifier);
    _notificationSub = connectionNotifier.notificationStream.listen(_handleServerEvent);
  }

  void _handleServerEvent(JsonRpcNotification notification) {
    final String type;
    final String? sid;
    final Map<String, dynamic> payload;

    if (notification.method == 'event' && notification.params is Map) {
      final p = Map<String, dynamic>.from(notification.params as Map);
      type = p['type']?.toString() ?? '';
      sid = p['session_id']?.toString() ?? p['sid']?.toString();
      payload = p['payload'] is Map ? Map<String, dynamic>.from(p['payload'] as Map) : {};
    } else {
      type = notification.method;
      sid = notification.params is Map
          ? (notification.params['session_id']?.toString() ?? notification.params['sid']?.toString())
          : null;
      payload = notification.params is Map ? Map<String, dynamic>.from(notification.params as Map) : {};
    }

    final targetTabIndex = _findTabForSession(sid);

    switch (type) {
      case 'message.start':
        _onMessageStart(targetTabIndex);
        break;

      case 'message.delta':
      case 'token.stream':
      case 'prompt.token':
        final token = payload['text']?.toString() ?? payload['token']?.toString() ?? '';
        _appendStreamingToken(targetTabIndex, token);
        break;

      case 'reasoning.delta':
      case 'thinking.delta':
      case 'token.thought':
      case 'prompt.thought':
        final thought = payload['text']?.toString() ?? payload['thought']?.toString() ?? '';
        _appendThinkingToken(targetTabIndex, thought);
        break;

      case 'reasoning.available':
        final thought = payload['text']?.toString() ?? '';
        _appendThinkingToken(targetTabIndex, thought);
        break;

      case 'message.complete':
      case 'prompt.done':
      case 'turn.finish':
        final finalText = payload['text']?.toString();
        _finalizeStreaming(targetTabIndex, finalText: finalText);
        break;

      case 'session.title':
        final newTitle = payload['title']?.toString();
        if (newTitle != null && newTitle.isNotEmpty) {
          _updateSessionTitle(targetTabIndex, newTitle);
        }
        break;

      case 'tool.start':
      case 'tool.call':
        final toolCall = ToolCall(
          id: payload['tool_id']?.toString() ??
              payload['id']?.toString() ??
              'tool_${DateTime.now().millisecondsSinceEpoch}',
          tool: payload['name']?.toString() ?? payload['tool']?.toString() ?? 'tool',
          args: payload['args'] is Map ? Map<String, dynamic>.from(payload['args'] as Map) : {},
        );
        _onToolStarted(targetTabIndex, toolCall);
        break;

      case 'tool.output':
      case 'tool.stream':
        final toolId = payload['tool_id']?.toString() ?? payload['id']?.toString() ?? '';
        final output = payload['output']?.toString() ?? '';
        _onToolOutput(targetTabIndex, toolId, output);
        break;

      case 'tool.complete':
      case 'tool.done':
      case 'tool.finish':
        final toolId = payload['tool_id']?.toString() ?? payload['id']?.toString() ?? '';
        final output = payload['result_text']?.toString() ??
            payload['summary']?.toString() ??
            payload['result']?.toString() ??
            '';
        final durationS = payload['duration_s'];
        final durationMs = durationS is num ? (durationS * 1000).toInt() : payload['duration_ms'] as int?;
        _onToolFinished(targetTabIndex, toolId, output, durationMs);
        break;

      case 'error':
        final errMsg = payload['message']?.toString() ?? 'Unknown session error';
        _onTurnError(targetTabIndex, errMsg);
        break;

      default:
        break;
    }
  }

  int _findTabForSession(String? sid) {
    if (sid == null || sid.isEmpty) return state.activeTabIndex;
    for (int i = 0; i < state.tabs.length; i++) {
      if (state.tabs[i].sessionId == sid) {
        return i;
      }
    }
    return state.activeTabIndex;
  }

  void _updateTab(int tabIndex, ChatTab Function(ChatTab) updater) {
    if (tabIndex < 0 || tabIndex >= state.tabs.length) return;
    final updatedTabs = List<ChatTab>.from(state.tabs);
    updatedTabs[tabIndex] = updater(updatedTabs[tabIndex]);
    state = state.copyWith(tabs: updatedTabs);
  }

  void _onMessageStart(int tabIndex) {
    _updateTab(tabIndex, (tab) {
      final messages = List<ChatMessage>.from(tab.messages);
      if (messages.isEmpty || messages.last.role != MessageRole.assistant || !messages.last.isStreaming) {
        messages.add(
          ChatMessage(
            id: 'ast_${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.assistant,
            content: '',
            timestamp: DateTime.now(),
            isStreaming: true,
          ),
        );
      }
      return tab.copyWith(messages: messages, isThinking: true);
    });
  }

  void _appendStreamingToken(int tabIndex, String token) {
    if (token.isEmpty) return;
    _updateTab(tabIndex, (tab) {
      final messages = List<ChatMessage>.from(tab.messages);
      if (messages.isEmpty || messages.last.role != MessageRole.assistant || !messages.last.isStreaming) {
        messages.add(
          ChatMessage(
            id: 'ast_${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.assistant,
            content: token,
            timestamp: DateTime.now(),
            isStreaming: true,
          ),
        );
      } else {
        final last = messages.last;
        messages[messages.length - 1] = last.copyWith(content: last.content + token);
      }
      return tab.copyWith(messages: messages, isThinking: false);
    });
  }

  void _appendThinkingToken(int tabIndex, String thought) {
    if (thought.isEmpty) return;
    _updateTab(tabIndex, (tab) {
      final messages = List<ChatMessage>.from(tab.messages);
      if (messages.isEmpty || messages.last.role != MessageRole.assistant || !messages.last.isStreaming) {
        messages.add(
          ChatMessage(
            id: 'ast_${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.assistant,
            content: '',
            thought: thought,
            timestamp: DateTime.now(),
            isStreaming: true,
          ),
        );
      } else {
        final last = messages.last;
        messages[messages.length - 1] = last.copyWith(
          thought: (last.thought ?? '') + thought,
        );
      }
      return tab.copyWith(messages: messages, isThinking: true);
    });
  }

  void _finalizeStreaming(int tabIndex, {String? finalText}) {
    _updateTab(tabIndex, (tab) {
      final messages = List<ChatMessage>.from(tab.messages);
      if (messages.isNotEmpty) {
        final last = messages.last;
        if (last.role == MessageRole.assistant && last.isStreaming) {
          messages[messages.length - 1] = last.copyWith(
            content: (finalText != null && finalText.isNotEmpty) ? finalText : last.content,
            isStreaming: false,
          );
        }
      }
      return tab.copyWith(messages: messages, isThinking: false);
    });
  }

  void _onToolStarted(int tabIndex, ToolCall tool) {
    _updateTab(tabIndex, (tab) {
      final messages = List<ChatMessage>.from(tab.messages);
      if (messages.isEmpty || messages.last.role != MessageRole.assistant || !messages.last.isStreaming) {
        messages.add(
          ChatMessage(
            id: 'ast_${DateTime.now().millisecondsSinceEpoch}',
            role: MessageRole.assistant,
            content: '',
            toolCalls: [tool],
            timestamp: DateTime.now(),
            isStreaming: true,
          ),
        );
      } else {
        final last = messages.last;
        messages[messages.length - 1] = last.copyWith(toolCalls: [...last.toolCalls, tool]);
      }
      return tab.copyWith(messages: messages, isThinking: true);
    });
  }

  void _onToolOutput(int tabIndex, String toolId, String output) {
    _updateTab(tabIndex, (tab) {
      final messages = List<ChatMessage>.from(tab.messages);
      if (messages.isNotEmpty && messages.last.role == MessageRole.assistant) {
        final last = messages.last;
        final updatedTools = last.toolCalls.map((t) {
          if (t.id == toolId || toolId.isEmpty) {
            return t.copyWith(output: (t.output ?? '') + output);
          }
          return t;
        }).toList();
        messages[messages.length - 1] = last.copyWith(toolCalls: updatedTools);
      }
      return tab.copyWith(messages: messages);
    });
  }

  void _onToolFinished(int tabIndex, String toolId, String output, int? durationMs) {
    _updateTab(tabIndex, (tab) {
      final messages = List<ChatMessage>.from(tab.messages);
      if (messages.isNotEmpty && messages.last.role == MessageRole.assistant) {
        final last = messages.last;
        final updatedTools = last.toolCalls.map((t) {
          if (t.id == toolId || toolId.isEmpty) {
            return t.copyWith(
              output: output.isNotEmpty ? output : t.output,
              status: ToolExecutionStatus.done,
              durationMs: durationMs ?? t.durationMs,
            );
          }
          return t;
        }).toList();
        messages[messages.length - 1] = last.copyWith(toolCalls: updatedTools);
      }
      return tab.copyWith(messages: messages);
    });
  }

  void _onTurnError(int tabIndex, String errorMessage) {
    _updateTab(tabIndex, (tab) {
      final messages = List<ChatMessage>.from(tab.messages);
      messages.add(
        ChatMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.system,
          content: 'Error: $errorMessage',
          timestamp: DateTime.now(),
        ),
      );
      return tab.copyWith(messages: messages, isThinking: false);
    });
  }

  void _updateSessionTitle(int tabIndex, String title) {
    _updateTab(tabIndex, (tab) => tab.copyWith(title: title));
  }

  void updateTabTitleBySessionId(String sessionId, String title) {
    for (int i = 0; i < state.tabs.length; i++) {
      if (state.tabs[i].sessionId == sessionId) {
        _updateTab(i, (tab) => tab.copyWith(title: title));
      }
    }
  }

  // --- TAB MANAGEMENT ---

  void createNewTab({String? title, String? sessionId, List<ChatMessage>? initialMessages}) {
    _tabCounter++;
    final newTab = ChatTab(
      id: 'tab_$_tabCounter',
      sessionId: sessionId,
      title: title ?? 'Chat $_tabCounter',
      messages: initialMessages ??
          [
            ChatMessage(
              id: 'tab_welcome_${DateTime.now().millisecondsSinceEpoch}',
              role: MessageRole.system,
              content: 'New chat tab ready. Type a prompt or / command.',
              timestamp: DateTime.now(),
            ),
          ],
    );

    final updatedTabs = [...state.tabs, newTab];
    state = state.copyWith(
      tabs: updatedTabs,
      activeTabIndex: updatedTabs.length - 1,
    );
  }

  void selectTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = state.copyWith(activeTabIndex: index);
      final currentSession = state.tabs[index].sessionId;
      if (currentSession != null) {
        _ref.read(sessionProvider.notifier).setActiveSession(currentSession);
      }
    }
  }

  void closeTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;

    if (state.tabs.length <= 1) {
      // Reset the only remaining tab
      state = state.copyWith(
        tabs: [
          ChatTab(
            id: 'tab_reset_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Chat 1',
            messages: [
              ChatMessage(
                id: 'init_welcome_${DateTime.now().millisecondsSinceEpoch}',
                role: MessageRole.system,
                content: 'Chat session reset. Send a message to begin.',
                timestamp: DateTime.now(),
              ),
            ],
          ),
        ],
        activeTabIndex: 0,
      );
      return;
    }

    final updatedTabs = List<ChatTab>.from(state.tabs)..removeAt(index);
    final newActiveIndex = state.activeTabIndex >= updatedTabs.length
        ? updatedTabs.length - 1
        : (state.activeTabIndex > index ? state.activeTabIndex - 1 : state.activeTabIndex);

    state = state.copyWith(
      tabs: updatedTabs,
      activeTabIndex: newActiveIndex,
    );
  }

  // --- PROMPTING & COMMANDS ---

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Check for client-handled slash commands
    if (trimmed.startsWith('/')) {
      final parts = trimmed.split(' ');
      final cmd = parts[0].toLowerCase();
      final args = parts.length > 1 ? parts.sublist(1).join(' ').trim() : '';

      if (cmd == '/new') {
        startNewSession();
        return;
      }
      if (cmd == '/clear') {
        clearMessages();
        return;
      }
      if (cmd == '/help') {
        _handleHelpCommand();
        return;
      }
      if (cmd == '/skills') {
        _handleSkillsCommand();
        return;
      }
      if (cmd == '/model') {
        if (args.isNotEmpty) {
          _handleModelSwitch(args);
          return;
        } else {
          _handleModelListHelp();
          return;
        }
      }
      if (cmd == '/reasoning') {
        if (args.isNotEmpty) {
          _handleReasoningSwitch(args);
          return;
        } else {
          _handleReasoningListHelp();
          return;
        }
      }
    }

    final activeIndex = state.activeTabIndex;
    final currentTab = state.activeTab;

    final userMessage = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    _updateTab(activeIndex, (tab) {
      return tab.copyWith(
        messages: [...tab.messages, userMessage],
        isThinking: true,
      );
    });

    final conn = _ref.read(connectionProvider);
    if (!conn.status.isConnected) {
      final offlineWarning = ChatMessage(
        id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
        role: MessageRole.system,
        content: 'Cannot send message: WebSocket is disconnected (${conn.serverUrl}). Verify hermes serve is active.',
        timestamp: DateTime.now(),
      );
      _updateTab(activeIndex, (tab) {
        return tab.copyWith(
          messages: [...tab.messages, offlineWarning],
          isThinking: false,
        );
      });
      return;
    }

    try {
      final repo = _ref.read(hermesRepositoryProvider);

      // If no active session in this tab, create one
      String? sessionId = currentTab.sessionId;
      if (sessionId == null || sessionId.isEmpty) {
        final activeProject = _ref.read(projectProvider).activeProject;
        final title = trimmed.length > 40 ? '${trimmed.substring(0, 40)}...' : trimmed;
        final newSession = await repo.createSession(
          title: title,
          cwd: activeProject?.path,
          project: activeProject?.name,
        );
        sessionId = newSession.id;
        _updateTab(activeIndex, (tab) => tab.copyWith(sessionId: sessionId, title: title));
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
      _updateTab(activeIndex, (tab) {
        return tab.copyWith(
          messages: [...tab.messages, errorMsg],
          isThinking: false,
        );
      });
    }
  }

  void _handleHelpCommand() {
    final now = DateTime.now();
    final activeIndex = state.activeTabIndex;

    _updateTab(activeIndex, (tab) {
      return tab.copyWith(
        messages: [
          ...tab.messages,
          ChatMessage(
            id: 'usr_${now.millisecondsSinceEpoch}',
            role: MessageRole.user,
            content: '/help',
            timestamp: now,
          ),
          ChatMessage(
            id: 'sys_${now.millisecondsSinceEpoch + 1}',
            role: MessageRole.assistant,
            content: '''
### Available Commands & Controls

| Command | Usage | Description |
|---|---|---|
| `/model` | `/model <name>` | Switch active model (e.g. `/model AG-gemini`, `/model AG-claude`) |
| `/reasoning` | `/reasoning <level>` | Set reasoning effort (`none`, `low`, `medium`, `high`, `ultra`) |
| `/new` | `/new` | Start a fresh session with default home or active workspace |
| `/clear` | `/clear` | Clear message history in the current buffer |
| `/skills` | `/skills` | Display all loaded skills and categories |
| `/help` | `/help` | Display this command guide |

---
**Skill Trigger Examples:**
Type `/` in chat to autocomplete 100+ skills:
- `/reverse-engineer-anything <target>`
- `/no-ai-slop <draft>`
- `/flutter-engineering <spec>`
- `/frontend-ui-engineering <spec>`
- `/systematic-debugging <issue>`
''',
            timestamp: now,
          ),
        ],
        isThinking: false,
      );
    });
  }

  void _handleSkillsCommand() {
    final now = DateTime.now();
    final skillsMap = _ref.read(skillsProvider).categorizedSkills;
    final activeIndex = state.activeTabIndex;

    final buffer = StringBuffer();
    buffer.writeln('### Installed Hermes Skills\n');

    if (skillsMap.isEmpty) {
      buffer.writeln('No skills loaded yet. Check daemon connection.');
    } else {
      skillsMap.forEach((category, list) {
        buffer.writeln('#### **${category.toUpperCase()}**');
        for (final skill in list) {
          final cleanName = skill.contains('/') ? skill.split('/').last : skill;
          buffer.writeln('- `/$cleanName` ($skill)');
        }
        buffer.writeln();
      });
    }

    _updateTab(activeIndex, (tab) {
      return tab.copyWith(
        messages: [
          ...tab.messages,
          ChatMessage(
            id: 'usr_${now.millisecondsSinceEpoch}',
            role: MessageRole.user,
            content: '/skills',
            timestamp: now,
          ),
          ChatMessage(
            id: 'sys_${now.millisecondsSinceEpoch + 1}',
            role: MessageRole.assistant,
            content: buffer.toString(),
            timestamp: now,
          ),
        ],
        isThinking: false,
      );
    });
  }

  void _handleModelSwitch(String modelName) async {
    final now = DateTime.now();
    final activeIndex = state.activeTabIndex;

    _updateTab(activeIndex, (tab) {
      return tab.copyWith(
        messages: [
          ...tab.messages,
          ChatMessage(
            id: 'usr_${now.millisecondsSinceEpoch}',
            role: MessageRole.user,
            content: '/model $modelName',
            timestamp: now,
          ),
        ],
        isThinking: true,
      );
    });

    try {
      await _ref.read(modelConfigProvider.notifier).setModel(modelName);
      _updateTab(activeIndex, (tab) {
        return tab.copyWith(
          messages: [
            ...tab.messages,
            ChatMessage(
              id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
              role: MessageRole.assistant,
              content: 'Model successfully switched to **$modelName**.',
              timestamp: DateTime.now(),
            ),
          ],
          isThinking: false,
        );
      });
    } catch (e) {
      _updateTab(activeIndex, (tab) {
        return tab.copyWith(
          messages: [
            ...tab.messages,
            ChatMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              role: MessageRole.system,
              content: 'Failed to switch model: $e',
              timestamp: DateTime.now(),
            ),
          ],
          isThinking: false,
        );
      });
    }
  }

  void _handleModelListHelp() {
    final now = DateTime.now();
    final modelState = _ref.read(modelConfigProvider);
    final active = modelState.config.activeModel;
    final all = modelState.config.allAvailableModels;
    final activeIndex = state.activeTabIndex;

    _updateTab(activeIndex, (tab) {
      return tab.copyWith(
        messages: [
          ...tab.messages,
          ChatMessage(
            id: 'usr_${now.millisecondsSinceEpoch}',
            role: MessageRole.user,
            content: '/model',
            timestamp: now,
          ),
          ChatMessage(
            id: 'sys_${now.millisecondsSinceEpoch + 1}',
            role: MessageRole.assistant,
            content: '''
### Active Model: `$active`

To change model, type `/model <model_name>`:
${all.map((m) => '- `/model $m`').join('\n')}
''',
            timestamp: now,
          ),
        ],
        isThinking: false,
      );
    });
  }

  void _handleReasoningSwitch(String effort) async {
    final now = DateTime.now();
    final cleanEffort = effort.toLowerCase();
    const valid = ['none', 'low', 'medium', 'high', 'ultra'];
    final activeIndex = state.activeTabIndex;

    if (!valid.contains(cleanEffort)) {
      _handleReasoningListHelp();
      return;
    }

    _updateTab(activeIndex, (tab) {
      return tab.copyWith(
        messages: [
          ...tab.messages,
          ChatMessage(
            id: 'usr_${now.millisecondsSinceEpoch}',
            role: MessageRole.user,
            content: '/reasoning $cleanEffort',
            timestamp: now,
          ),
        ],
        isThinking: true,
      );
    });

    try {
      final currentModel = _ref.read(modelConfigProvider).config.activeModel;
      await _ref.read(modelConfigProvider.notifier).setModel(
            currentModel,
            reasoningEffort: cleanEffort,
          );
      _updateTab(activeIndex, (tab) {
        return tab.copyWith(
          messages: [
            ...tab.messages,
            ChatMessage(
              id: 'sys_${DateTime.now().millisecondsSinceEpoch}',
              role: MessageRole.assistant,
              content: 'Reasoning effort set to **${cleanEffort.toUpperCase()}**.',
              timestamp: DateTime.now(),
            ),
          ],
          isThinking: false,
        );
      });
    } catch (e) {
      _updateTab(activeIndex, (tab) {
        return tab.copyWith(
          messages: [
            ...tab.messages,
            ChatMessage(
              id: 'err_${DateTime.now().millisecondsSinceEpoch}',
              role: MessageRole.system,
              content: 'Failed to set reasoning: $e',
              timestamp: DateTime.now(),
            ),
          ],
          isThinking: false,
        );
      });
    }
  }

  void _handleReasoningListHelp() {
    final now = DateTime.now();
    final current = _ref.read(modelConfigProvider).config.reasoningEffort;
    final activeIndex = state.activeTabIndex;

    _updateTab(activeIndex, (tab) {
      return tab.copyWith(
        messages: [
          ...tab.messages,
          ChatMessage(
            id: 'usr_${now.millisecondsSinceEpoch}',
            role: MessageRole.user,
            content: '/reasoning',
            timestamp: now,
          ),
          ChatMessage(
            id: 'sys_${now.millisecondsSinceEpoch + 1}',
            role: MessageRole.assistant,
            content: '''
### Current Reasoning Effort: `${current.toUpperCase()}`

Available options:
- `/reasoning none`
- `/reasoning low`
- `/reasoning medium`
- `/reasoning high`
- `/reasoning ultra`
''',
            timestamp: now,
          ),
        ],
        isThinking: false,
      );
    });
  }

  void loadResumedSession(String sessionId, List<dynamic> rawMessages, {String? title}) {
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

    final displayTitle = title ?? 'Session ${sessionId.length > 8 ? sessionId.substring(0, 8) : sessionId}';

    // Check if an existing tab already has this session
    for (int i = 0; i < state.tabs.length; i++) {
      if (state.tabs[i].sessionId == sessionId) {
        _updateTab(i, (tab) => tab.copyWith(messages: parsed, isThinking: false));
        state = state.copyWith(activeTabIndex: i);
        return;
      }
    }

    // If current tab is brand new and has no messages, re-use it
    final currentTab = state.activeTab;
    if (currentTab.sessionId == null &&
        (currentTab.messages.isEmpty ||
            (currentTab.messages.length == 1 && currentTab.messages.first.isSystem))) {
      _updateTab(state.activeTabIndex, (tab) {
        return tab.copyWith(
          sessionId: sessionId,
          title: displayTitle,
          messages: parsed,
          isThinking: false,
        );
      });
      return;
    }

    // Otherwise, create a new tab for this resumed session
    createNewTab(
      sessionId: sessionId,
      title: displayTitle,
      initialMessages: parsed,
    );
  }

  void startNewSession() {
    createNewTab(title: 'Chat ${_tabCounter + 1}');
  }

  void clearMessages() {
    _updateTab(state.activeTabIndex, (tab) {
      return tab.copyWith(
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
    });
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
