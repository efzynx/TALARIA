import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/chat_message.dart';
import '../../../data/models/slash_command.dart';
import '../../../state/approval_provider.dart';
import '../../../state/chat_provider.dart';
import '../../../state/model_provider.dart';
import '../../../state/skills_provider.dart';
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

  bool _isSlashCommandOpen = false;
  List<SlashCommandItem> _slashMatches = [];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text;
    if (text.startsWith('/') && !text.contains(' ') && !text.contains('\n')) {
      final matches = ref.read(skillsProvider.notifier).search(text);
      setState(() {
        _isSlashCommandOpen = true;
        _slashMatches = matches.take(8).toList();
      });
    } else {
      if (_isSlashCommandOpen) {
        setState(() {
          _isSlashCommandOpen = false;
          _slashMatches = [];
        });
      }
    }
  }

  void _applySlashCommand(SlashCommandItem item) {
    AppHaptics.light();
    if (item.trigger == '/new') {
      _textController.clear();
      setState(() => _isSlashCommandOpen = false);
      ref.read(chatProvider.notifier).startNewSession();
    } else if (item.trigger == '/clear') {
      _textController.clear();
      setState(() => _isSlashCommandOpen = false);
      ref.read(chatProvider.notifier).clearMessages();
    } else if (item.trigger == '/model') {
      setState(() => _isSlashCommandOpen = false);
      _showModelPickerSheet(context, ref);
    } else if (item.trigger == '/reasoning') {
      setState(() => _isSlashCommandOpen = false);
      _showReasoningPickerSheet(context, ref);
    } else {
      _textController.text = '${item.trigger} ';
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
      setState(() => _isSlashCommandOpen = false);
      _focusNode.requestFocus();
    }
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

    setState(() => _isSlashCommandOpen = false);
    AppHaptics.medium();
    ref.read(chatProvider.notifier).sendMessage(text);
    _textController.clear();
    _scrollToBottom();
  }

  void _showModelPickerSheet(BuildContext context, WidgetRef ref) {
    AppHaptics.light();
    final modelState = ref.read(modelConfigProvider);
    final allModels = modelState.config.allAvailableModels;
    final currentActive = modelState.config.activeModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: const BoxDecoration(
                          color: AppColors.border,
                          borderRadius: AppSpacing.roundedFull,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(LucideIcons.cpu, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Select Active Model',
                          style: AppTypography.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          tooltip: 'Sync Models',
                          onPressed: () async {
                            await ref.read(modelConfigProvider.notifier).fetchModelOptions();
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Switch the LLM model running your Hermes Agent turns:',
                      style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: allModels.isEmpty
                          ? Center(
                              child: Text(
                                'No models found. Check daemon connection.',
                                style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: allModels.length,
                              itemBuilder: (ctx, index) {
                                final model = allModels[index];
                                final isSelected = model == currentActive;

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.surfaceHover : AppColors.background,
                                    borderRadius: AppSpacing.roundedSm,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.border,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                    title: Text(
                                      model,
                                      style: AppTypography.mono(
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(LucideIcons.check, size: 16, color: AppColors.primary)
                                        : null,
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      ref.read(modelConfigProvider.notifier).setModel(model);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Model switched to $model', style: AppTypography.textTheme.bodySmall),
                                          backgroundColor: AppColors.surface,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReasoningPickerSheet(BuildContext context, WidgetRef ref) {
    AppHaptics.light();
    final modelState = ref.read(modelConfigProvider);
    final currentModel = modelState.config.activeModel;
    final currentEffort = modelState.config.reasoningEffort;

    const options = [
      {'level': 'none', 'label': 'None', 'desc': 'Standard generation with no explicit reasoning chain.'},
      {'level': 'low', 'label': 'Low', 'desc': 'Fast thinking for light questions and basic coding stubs.'},
      {'level': 'medium', 'label': 'Medium', 'desc': 'Balanced thought budget for typical tasks.'},
      {'level': 'high', 'label': 'High (Recommended)', 'desc': 'Deep exploration and self-correction for complex problems.'},
      {'level': 'ultra', 'label': 'Ultra', 'desc': 'Maximum deliberation budget for architecture & security sweeps.'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      borderRadius: AppSpacing.roundedFull,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(LucideIcons.brain, size: 18, color: AppColors.thinking),
                    const SizedBox(width: 8),
                    Text(
                      'Reasoning Effort Level',
                      style: AppTypography.textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sets the deliberation budget for $currentModel:',
                  style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                ...options.map((opt) {
                  final level = opt['level']!;
                  final isSelected = level == currentEffort;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surfaceHover : AppColors.background,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(
                        color: isSelected ? AppColors.thinking : AppColors.border,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      title: Text(
                        opt['label']!,
                        style: AppTypography.mono(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? AppColors.thinking : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        opt['desc']!,
                        style: AppTypography.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(LucideIcons.check, size: 16, color: AppColors.thinking)
                          : null,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        ref.read(modelConfigProvider.notifier).setModel(
                              currentModel,
                              reasoningEffort: level,
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reasoning effort set to ${level.toUpperCase()}',
                              style: AppTypography.textTheme.bodySmall,
                            ),
                            backgroundColor: AppColors.surface,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final modelState = ref.watch(modelConfigProvider);
    final messages = chatState.messages;

    final activeModel = modelState.config.activeModel;
    final activeReasoning = modelState.config.reasoningEffort;

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
            // Controls Bar (Model Pill, Reasoning Pill, Session Pill, New Session)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Model Pill
                    InkWell(
                      onTap: () => _showModelPickerSheet(context, ref),
                      borderRadius: AppSpacing.roundedSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(color: AppColors.primary.withAlpha(120)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.cpu, size: 13, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Text(
                              activeModel,
                              style: AppTypography.mono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.chevronDown, size: 11, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Reasoning Effort Pill
                    InkWell(
                      onTap: () => _showReasoningPickerSheet(context, ref),
                      borderRadius: AppSpacing.roundedSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(color: AppColors.thinking.withAlpha(120)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.brain, size: 13, color: AppColors.thinking),
                            const SizedBox(width: 5),
                            Text(
                              activeReasoning.toUpperCase(),
                              style: AppTypography.mono(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.thinking,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.chevronDown, size: 11, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Session Info Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            chatState.activeSessionId != null ? LucideIcons.radio : LucideIcons.plusCircle,
                            size: 12,
                            color: chatState.activeSessionId != null ? AppColors.ok : AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            chatState.activeSessionId != null
                                ? 'ID: ${chatState.activeSessionId!.length > 8 ? chatState.activeSessionId!.substring(0, 8) : chatState.activeSessionId}'
                                : 'NEW',
                            style: AppTypography.mono(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(LucideIcons.plus, size: 16),
                      color: AppColors.primary,
                      tooltip: 'New Session',
                      onPressed: () {
                        AppHaptics.light();
                        ref.read(chatProvider.notifier).startNewSession();
                      },
                    ),
                  ],
                ),
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

            // Floating Slash Command Autocomplete Overlay
            if (_isSlashCommandOpen && _slashMatches.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: AppColors.primary.withAlpha(140), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(140),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: _slashMatches.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final item = _slashMatches[index];
                    return InkWell(
                      onTap: () => _applySlashCommand(item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (item.type == SlashCommandType.skill ? AppColors.thinking : AppColors.primary).withAlpha(30),
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Text(
                                item.type == SlashCommandType.skill ? 'SKILL' : 'CMD',
                                style: AppTypography.mono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: item.type == SlashCommandType.skill ? AppColors.thinking : AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.trigger,
                                    style: AppTypography.mono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Text(
                                    item.description,
                                    style: AppTypography.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
            'Type / for commands, skills, or prompt instructions.',
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
                hintText: 'Type / for commands, skills, or prompt...',
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
