import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/network/connection_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/session.dart';
import '../../../state/chat_provider.dart';
import '../../../state/connection_provider.dart';
import '../../../state/project_provider.dart';
import '../../../state/session_provider.dart';
import '../../navigation/app_shell.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  void _showNewSessionDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.plusCircle, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Create New Session', style: AppTypography.textTheme.titleMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Title',
              style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: titleController,
              autofocus: true,
              style: AppTypography.textTheme.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'e.g. Flutter mobile development',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              Navigator.of(ctx).pop();
              if (title.isNotEmpty) {
                final activeProject = ref.read(projectProvider).activeProject;
                final newSession = await ref.read(sessionProvider.notifier).createSession(
                      title: title,
                      project: activeProject?.name,
                    );
                if (newSession != null) {
                  ref.read(chatProvider.notifier).startNewSession();
                  ref.read(activeTabProvider.notifier).state = 0;
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _resumeSession(
    BuildContext context,
    WidgetRef ref,
    HermesSession session,
  ) async {
    AppHaptics.medium();
    try {
      final result = await ref.read(sessionProvider.notifier).resumeSession(session.id);
      final runtimeId = result['session_id'] as String? ?? session.id;
      final rawMessages = result['messages'] as List? ?? [];
      ref.read(chatProvider.notifier).loadResumedSession(runtimeId, rawMessages);
      ref.read(activeTabProvider.notifier).state = 0;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resumed: ${session.title}', style: AppTypography.textTheme.bodySmall),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resume: $e', style: AppTypography.textTheme.bodySmall),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final sessionState = ref.watch(sessionProvider);
    final sessions = sessionState.sessions;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AGENT SESSIONS',
                    style: AppTypography.mono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        color: AppColors.textSecondary,
                        tooltip: 'Refresh Sessions',
                        onPressed: conn.status.isConnected
                            ? () {
                                AppHaptics.light();
                                ref.read(sessionProvider.notifier).fetchSessions();
                              }
                            : null,
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        icon: const Icon(LucideIcons.plus, size: 14),
                        label: const Text('New'),
                        onPressed: conn.status.isConnected
                            ? () => _showNewSessionDialog(context, ref)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (sessionState.isLoading)
                const LinearProgressIndicator(
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),

              const SizedBox(height: 8),

              Expanded(
                child: sessions.isEmpty
                    ? _buildEmptyState(conn.status.isConnected)
                    : ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          final isActive = session.id == sessionState.activeSessionId;
                          return _buildSessionCard(context, ref, session, isActive);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isConnected) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              LucideIcons.layers,
              size: 36,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Agent Sessions Found',
            style: AppTypography.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            isConnected
                ? 'Create a new session to organize your Hermes tasks.'
                : 'Connect to daemon to load and manage sessions.',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    WidgetRef ref,
    HermesSession session,
    bool isActive,
  ) {
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(session.updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceHover : AppColors.surface,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isActive ? AppColors.borderHighlight : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.title,
                style: AppTypography.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.primary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.primary, width: 0.5),
                ),
                child: Text(
                  'ACTIVE',
                  style: AppTypography.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                if (session.project != null) ...[
                  const Icon(LucideIcons.folder, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    session.project!,
                    style: AppTypography.mono(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 10),
                ],
                const Icon(LucideIcons.clock, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(LucideIcons.moreVertical, size: 18, color: AppColors.textMuted),
          color: AppColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
            side: BorderSide(color: AppColors.border),
          ),
          onSelected: (val) {
            if (val == 'resume') {
              _resumeSession(context, ref, session);
            } else if (val == 'delete') {
              ref.read(sessionProvider.notifier).deleteSession(session.id);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'resume',
              child: Row(
                children: [
                  Icon(LucideIcons.play, size: 14, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Resume Session'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(LucideIcons.trash2, size: 14, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          _resumeSession(context, ref, session);
        },
      ),
    );
  }
}
