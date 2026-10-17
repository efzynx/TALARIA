import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/connection_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../state/connection_provider.dart';
import '../../state/project_provider.dart';

class HermesStatusBar extends ConsumerWidget {
  final VoidCallback? onTerminalToggle;

  const HermesStatusBar({super.key, this.onTerminalToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final projectState = ref.watch(projectProvider);
    final activeProject = projectState.activeProject;

    final isOnline = conn.status.isConnected;
    final latency = conn.latencyMs;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Left side: git, backend status, workspace — scrollable on small screens
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
          // Git branch
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.gitBranch, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'main',
                style: AppTypography.mono(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Backend Status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.ok : AppColors.error,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isOnline
                    ? (latency != null ? 'Backend ready (${latency}ms)' : 'Backend ready')
                    : 'Disconnected',
                style: AppTypography.mono(
                  fontSize: 11,
                  color: isOnline ? AppColors.ok : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Active Workspace
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.folder, size: 11, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                activeProject?.name ?? 'talaria',
                style: AppTypography.mono(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
                ],
              ),
            ),
          ),

          // Terminal trigger button
          if (onTerminalToggle != null)
            InkWell(
              onTap: () {
                AppHaptics.light();
                onTerminalToggle!();
              },
              borderRadius: AppSpacing.roundedSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.terminal, size: 11, color: AppColors.thinking),
                    const SizedBox(width: 4),
                    Text(
                      'TERMINAL',
                      style: AppTypography.mono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.thinking,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(width: 8),

          // Smart Approvals Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.zap, size: 10, color: AppColors.primary),
                const SizedBox(width: 3),
                Text(
                  'Smart',
                  style: AppTypography.mono(fontSize: 10, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Version Tag
          Text(
            '# v0.22.2',
            style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
