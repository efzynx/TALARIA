import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../state/approval_provider.dart';
import '../screens/approvals/approvals_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/projects/projects_screen.dart';
import '../screens/sessions/sessions_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../widgets/connection_pill.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    ChatScreen(),
    SessionsScreen(),
    ProjectsScreen(),
    ApprovalsScreen(),
    SettingsScreen(),
  ];

  static const List<String> _titles = [
    'TALARIA / CHAT',
    'TALARIA / SESSIONS',
    'TALARIA / PROJECTS',
    'TALARIA / APPROVALS',
    'TALARIA / SETTINGS',
  ];

  @override
  Widget build(BuildContext context) {
    final approvalState = ref.watch(approvalProvider);
    final pendingCount = approvalState.count;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720;

        if (isDesktop) {
          return _buildDesktopLayout(pendingCount);
        } else {
          return _buildMobileLayout(pendingCount);
        }
      },
    );
  }

  /// Mobile Layout: Top AppBar with ConnectionPill + Bottom Navigation Bar
  Widget _buildMobileLayout(int pendingCount) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: AppTypography.mono(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: ConnectionPill(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.border,
            height: 1,
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: [
          const NavigationDestination(
            icon: Icon(LucideIcons.messageSquare),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(LucideIcons.layers),
            label: 'Sessions',
          ),
          const NavigationDestination(
            icon: Icon(LucideIcons.folderKanban),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: pendingCount > 0
                ? Badge.count(
                    count: pendingCount,
                    backgroundColor: AppColors.error,
                    textColor: Colors.white,
                    child: const Icon(LucideIcons.shieldAlert),
                  )
                : const Icon(LucideIcons.shieldCheck),
            label: 'Approvals',
          ),
          const NavigationDestination(
            icon: Icon(LucideIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  /// Desktop Layout: NavigationRail on left + Header with ConnectionPill + Content
  Widget _buildDesktopLayout(int pendingCount) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: const Icon(
                      LucideIcons.terminal,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TALARIA',
                    style: AppTypography.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            destinations: [
              const NavigationRailDestination(
                icon: Icon(LucideIcons.messageSquare),
                selectedIcon: Icon(LucideIcons.messageSquare, color: AppColors.primary),
                label: Text('Chat'),
              ),
              const NavigationRailDestination(
                icon: Icon(LucideIcons.layers),
                selectedIcon: Icon(LucideIcons.layers, color: AppColors.primary),
                label: Text('Sessions'),
              ),
              const NavigationRailDestination(
                icon: Icon(LucideIcons.folderKanban),
                selectedIcon: Icon(LucideIcons.folderKanban, color: AppColors.primary),
                label: Text('Projects'),
              ),
              NavigationRailDestination(
                icon: pendingCount > 0
                    ? Badge.count(
                        count: pendingCount,
                        backgroundColor: AppColors.error,
                        textColor: Colors.white,
                        child: const Icon(LucideIcons.shieldAlert),
                      )
                    : const Icon(LucideIcons.shieldCheck),
                selectedIcon: const Icon(LucideIcons.shieldCheck, color: AppColors.primary),
                label: const Text('Approvals'),
              ),
              const NavigationRailDestination(
                icon: Icon(LucideIcons.settings),
                selectedIcon: Icon(LucideIcons.settings, color: AppColors.primary),
                label: Text('Settings'),
              ),
            ],
          ),

          const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),

          // Main View Pane
          Expanded(
            child: Column(
              children: [
                // Desktop Header
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _titles[_selectedIndex],
                        style: AppTypography.mono(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const ConnectionPill(),
                    ],
                  ),
                ),

                // Screen Content
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
