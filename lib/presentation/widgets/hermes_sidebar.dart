import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/connection_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../state/chat_provider.dart';
import '../../state/connection_provider.dart';
import '../../state/project_provider.dart';
import '../../state/session_provider.dart';
import '../navigation/app_shell.dart';

class HermesSidebar extends ConsumerStatefulWidget {
  final VoidCallback? onClose;

  const HermesSidebar({super.key, this.onClose});

  @override
  ConsumerState<HermesSidebar> createState() => _HermesSidebarState();
}

class _HermesSidebarState extends ConsumerState<HermesSidebar> {
  bool _isSessionsTab = true; // true = SESSIONS, false = BOTS
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, dynamic>> _profiles = [
    {'name': 'default', 'label': 'H', 'color': Color(0xFF00E5FF)},
    {'name': 'pixel', 'label': 'P', 'color': Color(0xFFF43F5E)},
    {'name': 'forge', 'label': 'F', 'color': Color(0xFF10B981)},
    {'name': 'helm', 'label': 'H', 'color': Color(0xFFF59E0B)},
    {'name': 'atlas', 'label': 'A', 'color': Color(0xFF6366F1)},
    {'name': 'sentry', 'label': 'S', 'color': Color(0xFFEC4899)},
    {'name': 'ian', 'label': 'I', 'color': Color(0xFF38BDF8)},
  ];

  String _activeProfile = 'default';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionProvider);
    final sessionState = ref.watch(sessionProvider);
    final projectState = ref.watch(projectProvider);
    final activeProject = projectState.activeProject;

    final filteredSessions = sessionState.sessions.where((s) {
      if (_searchQuery.isEmpty) return true;
      return s.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      width: 290,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Header with Sessions / Bots Tab Switcher
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  _buildTabToggle('SESSIONS', _isSessionsTab, () {
                    setState(() => _isSessionsTab = true);
                  }),
                  const SizedBox(width: 14),
                  _buildTabToggle('BOTS', !_isSessionsTab, () {
                    setState(() => _isSessionsTab = false);
                  }),
                  const Spacer(),
                  if (widget.onClose != null)
                    InkWell(
                      onTap: widget.onClose,
                      borderRadius: BorderRadius.circular(99),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(LucideIcons.x, size: 16, color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),

            // Navigation Actions (New Session, Capabilities, Messaging, etc.)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: [
                  _buildActionButton(
                    icon: LucideIcons.plusCircle,
                    label: 'New session',
                    badge: 'Ctrl N',
                    onTap: () {
                      AppHaptics.light();
                      widget.onClose?.call();
                      ref.read(chatProvider.notifier).createNewTab();
                      ref.read(activeTabProvider.notifier).state = 0;
                    },
                    accentColor: AppColors.primary,
                  ),
                  _buildActionButton(
                    icon: LucideIcons.sparkles,
                    label: 'Capabilities',
                    onTap: () {
                      AppHaptics.light();
                      widget.onClose?.call();
                      ref.read(chatProvider.notifier).sendMessage('/skills');
                      ref.read(activeTabProvider.notifier).state = 0;
                    },
                  ),
                  _buildActionButton(
                    icon: LucideIcons.messageSquare,
                    label: 'Messaging',
                    onTap: () {
                      AppHaptics.light();
                      widget.onClose?.call();
                      ref.read(activeTabProvider.notifier).state = 0;
                    },
                  ),
                  _buildActionButton(
                    icon: LucideIcons.shieldAlert,
                    label: 'Approvals Gatekeeper',
                    onTap: () {
                      AppHaptics.light();
                      widget.onClose?.call();
                      ref.read(activeTabProvider.notifier).state = 3;
                    },
                  ),
                ],
              ),
            ),

            // Search Sessions Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.mono(fontSize: 12),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Search sessions...',
                    prefixIcon: Icon(LucideIcons.search, size: 14, color: AppColors.textMuted),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),

            const Divider(color: AppColors.border, height: 16),

            // Workspace & Git Branch Tree Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    activeProject != null ? LucideIcons.folder : LucideIcons.home,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      (activeProject?.name ?? 'DEFAULT HOME').toUpperCase(),
                      style: AppTypography.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppSpacing.roundedSm,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.gitBranch, size: 10, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'main',
                          style: AppTypography.mono(fontSize: 10, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Sessions List
            Expanded(
              child: filteredSessions.isEmpty
                  ? Center(
                      child: Text(
                        conn.status.isConnected ? 'No sessions' : 'Offline',
                        style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        final isActive = session.id == sessionState.activeSessionId;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.surfaceHover : Colors.transparent,
                            borderRadius: AppSpacing.roundedSm,
                            border: Border.all(
                              color: isActive ? AppColors.borderHighlight : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            leading: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? AppColors.ok : AppColors.textMuted,
                              ),
                            ),
                            title: Text(
                              session.title,
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                color: isActive ? AppColors.primary : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () async {
                              AppHaptics.light();
                              widget.onClose?.call();
                              final result = await ref.read(sessionProvider.notifier).resumeSession(session.id);
                              final runtimeId = result['session_id'] as String? ?? session.id;
                              final rawMessages = result['messages'] as List? ?? [];
                              ref.read(chatProvider.notifier).loadResumedSession(
                                    runtimeId,
                                    rawMessages,
                                    title: session.title,
                                  );
                              ref.read(activeTabProvider.notifier).state = 0;
                            },
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Profile Switcher Dock (Hermes Persona Badges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ..._profiles.map((p) {
                    final name = p['name'] as String;
                    final label = p['label'] as String;
                    final color = p['color'] as Color;
                    final isCurrent = name == _activeProfile;

                    return Tooltip(
                      message: 'Profile: $name',
                      child: InkWell(
                        onTap: () {
                          AppHaptics.light();
                          setState(() => _activeProfile = name);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Switched to profile: $name', style: AppTypography.textTheme.bodySmall),
                              backgroundColor: AppColors.surface,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent ? color.withAlpha(40) : AppColors.surface,
                            border: Border.all(
                              color: isCurrent ? color : AppColors.border,
                              width: isCurrent ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            style: AppTypography.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCurrent ? color : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildTabToggle(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.mono(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 50,
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    String? badge,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            Icon(icon, size: 15, color: accentColor ?? AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  badge,
                  style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
