import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/network/connection_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/haptics.dart';
import '../../../data/models/project.dart';
import '../../../state/connection_provider.dart';
import '../../../state/project_provider.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final pathController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.folderPlus, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Add Workspace Project', style: AppTypography.textTheme.titleMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Project Name', style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              autofocus: true,
              style: AppTypography.textTheme.bodyMedium,
              decoration: const InputDecoration(hintText: 'e.g. Talaria Remote'),
            ),
            const SizedBox(height: 12),
            Text('Absolute Directory Path', style: AppTypography.textTheme.labelSmall?.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 6),
            TextField(
              controller: pathController,
              style: AppTypography.mono(fontSize: 12),
              decoration: const InputDecoration(hintText: '/home/efzyn/Project/talaria'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final path = pathController.text.trim();
              if (name.isNotEmpty && path.isNotEmpty) {
                ref.read(projectProvider.notifier).createProject(name, path);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add Project'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final projectState = ref.watch(projectProvider);
    final projects = projectState.projects;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'WORKSPACE PROJECTS',
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
                        tooltip: 'Refresh Projects',
                        onPressed: conn.status.isConnected
                            ? () {
                                AppHaptics.light();
                                ref.read(projectProvider.notifier).loadProjects();
                              }
                            : null,
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        icon: const Icon(LucideIcons.plus, size: 14),
                        label: const Text('Add'),
                        onPressed: conn.status.isConnected
                            ? () => _showCreateProjectDialog(context, ref)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Active Workspace Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(
                    color: projectState.activeProject != null
                        ? AppColors.primary.withAlpha(120)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      projectState.activeProject != null
                          ? LucideIcons.folderCheck
                          : LucideIcons.home,
                      size: 18,
                      color: projectState.activeProject != null
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectState.activeProject != null
                                ? 'ACTIVE: ${projectState.activeProject!.name.toUpperCase()}'
                                : 'ACTIVE: DEFAULT HOME (~)',
                            style: AppTypography.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: projectState.activeProject != null
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            projectState.activeProject != null
                                ? projectState.activeProject!.path
                                : 'Sessions start in daemon default user directory.',
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
                    if (projectState.activeProject != null)
                      TextButton(
                        onPressed: () {
                          AppHaptics.light();
                          ref.read(projectProvider.notifier).setActiveProject(null);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Switched to default home workspace'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('Reset', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (projectState.isLoading)
                const LinearProgressIndicator(
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),

              const SizedBox(height: 8),

              Expanded(
                child: projects.isEmpty
                    ? _buildEmptyState(conn.status.isConnected)
                    : ListView.builder(
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          final isActive = project.isActive ||
                              project.id == projectState.activeProject?.id;
                          return _buildProjectCard(context, ref, project, isActive);
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
              LucideIcons.folderKanban,
              size: 36,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Workspace Projects',
            style: AppTypography.textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            isConnected
                ? 'Add workspaces to target agent file operations directly.'
                : 'Connect to daemon to inspect projects.',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _selectProject(BuildContext context, WidgetRef ref, HermesProject project, bool isActive) {
    AppHaptics.light();
    if (isActive) {
      ref.read(projectProvider.notifier).setActiveProject(null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deselected project. Using default home workspace.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ref.read(projectProvider.notifier).setActiveProject(project);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Active workspace set to ${project.name} (${project.path})'),
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildProjectCard(
    BuildContext context,
    WidgetRef ref,
    HermesProject project,
    bool isActive,
  ) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withAlpha(30) : AppColors.background,
            borderRadius: AppSpacing.roundedSm,
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Icon(
            LucideIcons.folder,
            size: 20,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                project.name,
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
                  'CURRENT WORKSPACE',
                  style: AppTypography.mono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            project.path,
            style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: isActive
            ? const Icon(LucideIcons.check, size: 18, color: AppColors.primary)
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(60, 32),
                ),
                onPressed: () => _selectProject(context, ref, project, isActive),
                child: const Text('Select', style: TextStyle(fontSize: 12)),
              ),
        onTap: () => _selectProject(context, ref, project, isActive),
      ),
    );
  }
}
