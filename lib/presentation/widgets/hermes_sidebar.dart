import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/network/connection_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/project_tree_node.dart';
import '../../state/account_provider.dart';
import '../../state/bots_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/connection_provider.dart';
import '../../state/project_provider.dart';
import '../../state/session_provider.dart';
import '../navigation/app_shell.dart';
import 'account_switcher_dialog.dart';

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

  // Set of project node IDs that are expanded
  final Set<String> _expandedNodeIds = {'__no_project__', 'default_home', 'gateway_sessions'};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleExpand(String id) {
    AppHaptics.light();
    setState(() {
      if (_expandedNodeIds.contains(id)) {
        _expandedNodeIds.remove(id);
      } else {
        _expandedNodeIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionProvider);
    final accountState = ref.watch(accountProvider);
    final sessionState = ref.watch(sessionProvider);
    final projectState = ref.watch(projectProvider);
    final botsState = ref.watch(botsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    return Container(
      width: 290,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Top Header: SESSIONS / BOTS Tabs + Minimize / Close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  _buildTabToggle('SESSIONS', _isSessionsTab, () {
                    AppHaptics.light();
                    setState(() => _isSessionsTab = true);
                  }),
                  const SizedBox(width: 14),
                  _buildTabToggle('BOTS', !_isSessionsTab, () {
                    AppHaptics.light();
                    setState(() => _isSessionsTab = false);
                  }),
                  const Spacer(),
                  // Minimize button (collapses sidebar on desktop or closes drawer on mobile)
                  Tooltip(
                    message: isDesktop ? 'Minimize sidebar' : 'Close sidebar',
                    child: InkWell(
                      onTap: () {
                        AppHaptics.light();
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else if (isDesktop) {
                          ref.read(sidebarOpenProvider.notifier).state = false;
                        }
                      },
                      borderRadius: BorderRadius.circular(99),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isDesktop ? LucideIcons.panelLeftClose : LucideIcons.x,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area (SESSIONS View vs BOTS View)
            Expanded(
              child: _isSessionsTab
                  ? _buildSessionsView(conn, accountState, sessionState, projectState)
                  : _buildBotsView(botsState),
            ),

            // Bottom Profile Switcher Dock (Hermes Persona Badges)
            _buildProfileDock(botsState),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsView(
    ConnectionStateData conn,
    AccountState accountState,
    SessionState sessionState,
    ProjectState projectState,
  ) {
    return Column(
      children: [
        // Navigation Actions (New Session, Capabilities, Messaging, Approvals, Accounts & Auth)
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
              _buildActionButton(
                icon: LucideIcons.users,
                label: 'Accounts & Auth',
                badge: '${accountState.accounts.length}',
                onTap: () {
                  AppHaptics.light();
                  AccountSwitcherDialog.show(context);
                },
                accentColor: AppColors.primary,
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

        // Multi-Project Tree & Gateway Sessions (Expandable & Minimizable)
        Expanded(
          child: _buildProjectsTreeSection(conn, sessionState, projectState),
        ),
      ],
    );
  }

  Widget _buildProjectsTreeSection(
    ConnectionStateData conn,
    SessionState sessionState,
    ProjectState projectState,
  ) {
    if (!conn.isConnected && conn.status != ConnectionStatus.unauthorized) {
      return Center(
        child: Text(
          'Offline',
          style: AppTypography.mono(fontSize: 11, color: AppColors.textMuted),
        ),
      );
    }

    final treeNodes = projectState.treeNodes;
    final allSessions = sessionState.sessions;

    // Filter sessions if search query is present
    final isSearching = _searchQuery.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      children: [
        // 1. Projects from Tree (Default Home + Other Projects)
        ...treeNodes.map((node) {
          final isExpanded = _expandedNodeIds.contains(node.id) || isSearching;
          final isHome = node.isNoProject;
          final isCurrentActive = !isHome && projectState.activeProject?.id == node.id;

          // Fully hydrate all sessions for this project node:
          // 1. Gather sessions from projects.tree (previewSessions / sessions)
          final Map<String, dynamic> sessionMap = {};
          for (final s in node.sessions) {
            sessionMap[s.id] = s;
          }

          // 2. Cross-reference with allSessions loaded from session.list
          for (final s in allSessions) {
            final belongsToNode = node.sessionIds.contains(s.id) ||
                (isHome && (s.project == null || s.project!.isEmpty || s.project == '__no_project__')) ||
                (!isHome && (s.project == node.id || s.project?.toLowerCase() == node.label.toLowerCase()));

            if (belongsToNode && !sessionMap.containsKey(s.id)) {
              sessionMap[s.id] = ProjectTreeSession(
                id: s.id,
                title: s.title,
                messageCount: s.messageCount,
                startedAt: s.createdAt,
              );
            }
          }

          List<dynamic> nodeSessions = sessionMap.values.toList();

          if (isSearching) {
            nodeSessions = nodeSessions.where((s) {
              final title = (s is ProjectTreeSession ? s.title : (s.title as String)).toLowerCase();
              return title.contains(_searchQuery.toLowerCase());
            }).toList();
          }

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project Header Row (Tap to expand/minimize)
                InkWell(
                  onTap: () => _toggleExpand(node.id),
                  borderRadius: AppSpacing.roundedSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: [
                        // Chevron Expand/Minimize Indicator
                        Icon(
                          isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),

                        // Project Icon (Home for default, Folder for projects)
                        Icon(
                          isHome ? LucideIcons.home : LucideIcons.folder,
                          size: 14,
                          color: isCurrentActive ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),

                        // Project Label
                        Expanded(
                          child: Text(
                            node.label.toUpperCase(),
                            style: AppTypography.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCurrentActive ? AppColors.primary : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Session Count Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.background,
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: Text(
                            '${nodeSessions.length}',
                            style: AppTypography.mono(fontSize: 9, color: AppColors.textMuted),
                          ),
                        ),

                        // Git Branch Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: AppSpacing.roundedSm,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.gitBranch, size: 9, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                node.gitBranch,
                                style: AppTypography.mono(fontSize: 9, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sessions underneath when expanded
                if (isExpanded) ...[
                  if (nodeSessions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 26, top: 2, bottom: 4),
                      child: Text(
                        'No sessions recorded',
                        style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 14),
                      child: Column(
                        children: nodeSessions.map((s) {
                          final String sid = s is ProjectTreeSession ? s.id : s.id;
                          final String stitle = s is ProjectTreeSession ? s.title : s.title;
                          final isActive = sid == sessionState.activeSessionId;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 1),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.surfaceHover : Colors.transparent,
                              borderRadius: AppSpacing.roundedSm,
                              border: Border.all(
                                color: isActive ? AppColors.borderHighlight : Colors.transparent,
                              ),
                            ),
                            child: ListTile(
                              dense: true,
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              leading: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive ? AppColors.ok : AppColors.textMuted,
                                ),
                              ),
                              title: Text(
                                stitle,
                                style: AppTypography.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () async {
                                AppHaptics.light();
                                widget.onClose?.call();
                                final result = await ref.read(sessionProvider.notifier).resumeSession(sid);
                                final runtimeId = result['session_id'] as String? ?? sid;
                                final rawMessages = result['messages'] as List? ?? [];
                                ref.read(chatProvider.notifier).loadResumedSession(
                                      runtimeId,
                                      rawMessages,
                                      title: stitle,
                                    );
                                ref.read(activeTabProvider.notifier).state = 0;
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ],
            ),
          );
        }),

        // 2. Fallback / Gateway Sessions Section
        if (allSessions.isNotEmpty && !treeNodes.any((n) => n.sessions.isNotEmpty)) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _toggleExpand('gateway_sessions'),
                  borderRadius: AppSpacing.roundedSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          _expandedNodeIds.contains('gateway_sessions')
                              ? LucideIcons.chevronDown
                              : LucideIcons.chevronRight,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.radio, size: 13, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'GATEWAY SESSIONS',
                          style: AppTypography.mono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${allSessions.length}',
                          style: AppTypography.mono(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expandedNodeIds.contains('gateway_sessions'))
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: Column(
                      children: allSessions.map((session) {
                        final isActive = session.id == sessionState.activeSessionId;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 1),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.surfaceHover : Colors.transparent,
                            borderRadius: AppSpacing.roundedSm,
                          ),
                          child: ListTile(
                            dense: true,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                            leading: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? AppColors.ok : AppColors.textMuted,
                              ),
                            ),
                            title: Text(
                              session.title,
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: isActive ? AppColors.primary : AppColors.textSecondary,
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
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// BOTS View: Displays the list of agent bots on this host/machine per profile
  Widget _buildBotsView(BotsState botsState) {
    final bots = botsState.bots;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              const Icon(LucideIcons.bot, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'HOST AGENT BOTS (${bots.length})',
                style: AppTypography.mono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Specialist agent personas configured on this Hermes machine:',
          style: AppTypography.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),

        ...bots.map((bot) {
          final isCurrent = bot.name == botsState.activeBotName;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.surfaceHover : AppColors.background,
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(
                color: isCurrent ? bot.badgeColor : AppColors.border,
                width: isCurrent ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bot.badgeColor.withAlpha(35),
                  border: Border.all(color: bot.badgeColor, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  bot.badgeLetter,
                  style: AppTypography.mono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: bot.badgeColor,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      bot.displayName,
                      style: AppTypography.mono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? bot.badgeColor : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (bot.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(color: AppColors.primary.withAlpha(100)),
                      ),
                      child: Text(
                        'CORE',
                        style: AppTypography.mono(fontSize: 8, color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    bot.description,
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppSpacing.roundedSm,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${bot.skillCount} skills',
                          style: AppTypography.mono(fontSize: 9, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                AppHaptics.light();
                ref.read(botsProvider.notifier).selectBot(bot.name);
                widget.onClose?.call();
                ref.read(chatProvider.notifier).createNewTab();
                ref.read(activeTabProvider.notifier).state = 0;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Switched active bot to ${bot.displayName}', style: AppTypography.textTheme.bodySmall),
                    backgroundColor: AppColors.surface,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  /// Profile Switcher Dock (H, P, F, H, A, S, I)
  Widget _buildProfileDock(BotsState botsState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: botsState.bots.map((bot) {
            final isCurrent = bot.name == botsState.activeBotName;

            return Tooltip(
              message: '${bot.displayName} (${bot.name})',
              child: InkWell(
                onTap: () {
                  AppHaptics.light();
                  ref.read(botsProvider.notifier).selectBot(bot.name);
                },
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent ? bot.badgeColor.withAlpha(40) : AppColors.surface,
                    border: Border.all(
                      color: isCurrent ? bot.badgeColor : AppColors.border,
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    bot.badgeLetter,
                    style: AppTypography.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? bot.badgeColor : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
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
