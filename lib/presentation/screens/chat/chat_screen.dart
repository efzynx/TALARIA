import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/chat_message.dart';
import '../../../state/approval_provider.dart';
import '../../../state/chat_provider.dart';
import '../../widgets/approval_sheet.dart';
import '../../widgets/tool_accordion.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    AppHaptics.medium();
    ref.read(chatProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;

    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    // Auto-surface Approval Modal Sheet when a pending approval arrives
    ref.listen(approvalProvider, (prev, next) {
      if (next.hasPending && (prev == null || prev.count < next.count)) {
        final latest = next.pendingApprovals.last;
        ApprovalSheet.show(context, latest);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Session Info & Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  Icon(
                    chatState.activeSessionId != null ? LucideIcons.radio : LucideIcons.plusCircle,
                    size: 14,
                    color: chatState.activeSessionId != null ? AppColors.ok : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.activeSessionId != null
                          ? 'SESSION: ${chatState.activeSessionId}'
                          : 'SESSION: NEW (DEFAULT AUTO-CREATE)',
                      style: AppTypography.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: chatState.activeSessionId != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (chatState.activeSessionId != null)
                    InkWell(
                      onTap: () {
                        AppHaptics.light();
                        ref.read(chatProvider.notifier).startNewSession();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.plus, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'New',
                              style: AppTypography.mono(fontSize: 10, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // List of Messages
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return _buildMessageItem(msg);
                      },
                    ),
            ),

            // Thinking Indicator (if model is thinking without output yet)
            if (chatState.isThinking)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.thinking),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Hermes is reasoning...',
                      style: AppTypography.mono(
                        fontSize: 12,
                        color: AppColors.thinking,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Thumb-Zone Input Bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.terminal, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'Ready to command Hermes Agent',
            style: AppTypography.textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type a prompt or task instruction below.',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.terminalSquare, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg.content,
                style: AppTypography.mono(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isUser = msg.isUser;
    final timeStr = DateFormat.Hm().format(msg.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.88,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? AppColors.surfaceHover : AppColors.surface,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: isUser ? AppColors.borderHighlight : AppColors.border,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Role & Time)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUser ? LucideIcons.send : LucideIcons.terminal,
                      size: 13,
                      color: isUser ? AppColors.primary : AppColors.thinking,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isUser ? 'YOU' : 'HERMES',
                      style: AppTypography.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isUser ? AppColors.primary : AppColors.thinking,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: AppTypography.mono(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),

                // Tool Execution Accordions (DESIGN.md & PRD 4: Collapsible Accordion Tools)
                if (msg.toolCalls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...msg.toolCalls.map((tool) => ToolAccordion(toolCall: tool)),
                ],

                // Reasoning Stream (if present)
                if (msg.thought != null && msg.thought!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      msg.thought!,
                      style: AppTypography.thinkingStream,
                    ),
                  ),
                ],

                if (msg.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  if (isUser)
                    SelectableText(
                      msg.content,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: msg.content,
                      selectable: true,
                      styleSheet: _buildMarkdownStyleSheet(),
                    ),
                ],

                if (msg.isStreaming) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 14,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet() {
    return MarkdownStyleSheet(
      p: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      h1: AppTypography.textTheme.headlineMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      h2: AppTypography.textTheme.titleLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      h3: AppTypography.textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      h4: AppTypography.textTheme.bodyLarge?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      code: AppTypography.mono(
        fontSize: 12,
        color: AppColors.primary,
        height: 1.4,
      ),
      codeblockPadding: const EdgeInsets.all(12),
      codeblockDecoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.border),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.background.withAlpha(120),
        borderRadius: AppSpacing.roundedSm,
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      listBullet: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.primary,
      ),
      a: AppTypography.textTheme.bodyMedium?.copyWith(
        color: AppColors.primary,
        decoration: TextDecoration.underline,
      ),
      tableBorder: TableBorder.all(color: AppColors.border, width: 1),
      tableHead: AppTypography.mono(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
      tableBody: AppTypography.mono(
        fontSize: 12,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: 4,
              minLines: 1,
              style: AppTypography.textTheme.bodyMedium,
              cursorColor: AppColors.primary,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: 'Command or prompt Hermes...',
                hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button (Electric Cyan background, Abyssal dark icon)
          InkWell(
            onTap: _handleSend,
            borderRadius: AppSpacing.roundedSm,
            child: Container(
              height: 44,
              width: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppSpacing.roundedSm,
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.send,
                size: 20,
                color: AppColors.background,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
