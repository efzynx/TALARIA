import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../screens/approvals/approvals_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/sessions/sessions_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../widgets/connection_pill.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    ChatScreen(),
    SessionsScreen(),
    ApprovalsScreen(),
    SettingsScreen(),
  ];

  static const List<String> _titles = [
    'TALARIA / CHAT',
    'TALARIA / SESSIONS',
    'TALARIA / APPROVALS',
    'TALARIA / SETTINGS',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720;

        if (isDesktop) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  /// Mobile Layout: Top AppBar with ConnectionPill + Bottom Navigation Bar
  Widget _buildMobileLayout() {
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
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.messageSquare),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.layers),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.shieldCheck),
            label: 'Approvals',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  /// Desktop Layout: NavigationRail on left + Header with ConnectionPill + Content
  Widget _buildDesktopLayout() {
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
            destinations: const [
              NavigationRailDestination(
                icon: Icon(LucideIcons.messageSquare),
                selectedIcon: Icon(LucideIcons.messageSquare, color: AppColors.primary),
                label: Text('Chat'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.layers),
                selectedIcon: Icon(LucideIcons.layers, color: AppColors.primary),
                label: Text('Sessions'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.shieldCheck),
                selectedIcon: Icon(LucideIcons.shieldCheck, color: AppColors.primary),
                label: Text('Approvals'),
              ),
              NavigationRailDestination(
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
