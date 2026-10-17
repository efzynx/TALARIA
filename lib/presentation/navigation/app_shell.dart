import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/haptics.dart';
import '../../state/account_provider.dart';
import '../../state/approval_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/connection_provider.dart';
import '../../state/model_provider.dart';
import '../screens/approvals/approvals_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/projects/projects_screen.dart';
import '../screens/sessions/sessions_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../widgets/account_switcher_dialog.dart';
import '../widgets/connection_pill.dart';
import '../widgets/hermes_sidebar.dart';
import '../widgets/hermes_status_bar.dart';

final activeTabProvider = StateProvider<int>((ref) => 0);
final sidebarOpenProvider = StateProvider<bool>((ref) => false);

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const List<Widget> _screens = [
    ChatScreen(),
    SessionsScreen(),
    ProjectsScreen(),
    ApprovalsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 720;
        if (isDesktop) {
        return const _DesktopShell(screens: _screens);
        } else {
        return const _MobileShell(screens: _screens);
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MOBILE SHELL — Slide-in Hermes-parity Sidebar + Bottom Nav
// ─────────────────────────────────────────────────────────────
class _MobileShell extends ConsumerWidget {
  final List<Widget> screens;

  const _MobileShell({required this.screens});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(activeTabProvider);
    final approvalState = ref.watch(approvalProvider);
    final pendingCount = approvalState.count;
    ref.watch(connectionProvider);
    final chatState = ref.watch(chatProvider);
    final modelState = ref.watch(modelConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        backgroundColor: AppColors.surface,
        width: 290,
        child: HermesSidebar(
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Top Header Bar (parity with Hermes Desktop header)
          _MobileHeader(
            selectedIndex: selectedIndex,
            pendingCount: pendingCount,
            chatState: chatState,
            modelState: modelState,
          ),
          // Screen Content
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: screens,
            ),
          ),
          // Hermes-style bottom status bar
          const HermesStatusBar(),
        ],
      ),
      bottomNavigationBar: _HermesBottomNav(
        selectedIndex: selectedIndex,
        pendingCount: pendingCount,
        onTap: (idx) {
          AppHaptics.light();
          ref.read(activeTabProvider.notifier).state = idx;
        },
      ),
    );
  }
}

class _MobileHeader extends ConsumerWidget {
  final int selectedIndex;
  final int pendingCount;
  final ChatState chatState;
  final ModelConfigState modelState;

  const _MobileHeader({
    required this.selectedIndex,
    required this.pendingCount,
    required this.chatState,
    required this.modelState,
  });

  static const _titles = [
    'CHAT',
    'SESSIONS',
    'PROJECTS',
    'APPROVALS',
    'SETTINGS',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeModel = modelState.config.activeModel;
    final reasoningEffort = modelState.config.reasoningEffort;
    final activeTab = chatState.activeTab;
    final isChat = selectedIndex == 0;

    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    // Hamburger (opens Hermes Sidebar)
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(LucideIcons.menu, size: 20),
                        color: AppColors.textSecondary,
                        padding: const EdgeInsets.all(8),
                        onPressed: () {
                          AppHaptics.light();
                          Scaffold.of(ctx).openDrawer();
                        },
                      ),
                    ),

                    // Title / Tab name
                    if (!isChat)
                      Text(
                        _titles[selectedIndex],
                        style: AppTypography.mono(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),

                    // Chat header: Model + Reasoning pills
                    if (isChat) ...[
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // Active Session title
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 110),
                                child: Text(
                                  activeTab.title,
                                  style: AppTypography.mono(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: 6),

                              // Model Pill
                              GestureDetector(
                                onTap: () => _showModelSheet(context, ref),
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
                                      const Icon(LucideIcons.cpu, size: 12, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        _trimModel(activeModel),
                                        style: AppTypography.mono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(LucideIcons.chevronDown, size: 10, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              // Reasoning Effort Pill
                              GestureDetector(
                                onTap: () => _showReasoningSheet(context, ref),
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
                                      const Icon(LucideIcons.brain, size: 12, color: AppColors.thinking),
                                      const SizedBox(width: 4),
                                      Text(
                                        reasoningEffort.toUpperCase(),
                                        style: AppTypography.mono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.thinking,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(LucideIcons.chevronDown, size: 10, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      const Spacer(),

                    // Connection Pill (right side of header, always visible)
                    const ConnectionPill(),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
          // Hairline separator
          Container(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  String _trimModel(String model) {
    // Shorten common model names for mobile header
    if (model.length <= 14) return model;
    return '${model.substring(0, 12)}…';
  }

  void _showModelSheet(BuildContext context, WidgetRef ref) {
    AppHaptics.light();
    final allModels = ref.read(modelConfigProvider).config.allAvailableModels;
    final currentActive = ref.read(modelConfigProvider).config.activeModel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ModelSheet(allModels: allModels, currentActive: currentActive),
    );
  }

  void _showReasoningSheet(BuildContext context, WidgetRef ref) {
    AppHaptics.light();
    final current = ref.read(modelConfigProvider).config.reasoningEffort;
    final model = ref.read(modelConfigProvider).config.activeModel;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ReasoningSheet(currentEffort: current, model: model),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────
class _HermesBottomNav extends StatelessWidget {
  final int selectedIndex;
  final int pendingCount;
  final ValueChanged<int> onTap;

  const _HermesBottomNav({
    required this.selectedIndex,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: LucideIcons.messageSquare, label: 'Chat', index: 0, selected: selectedIndex, onTap: onTap),
              _NavItem(icon: LucideIcons.layers, label: 'Sessions', index: 1, selected: selectedIndex, onTap: onTap),
              _NavItem(icon: LucideIcons.folderKanban, label: 'Projects', index: 2, selected: selectedIndex, onTap: onTap),
              _NavItem(
                icon: LucideIcons.shieldAlert,
                label: 'Approvals',
                index: 3,
                selected: selectedIndex,
                onTap: onTap,
                badge: pendingCount > 0 ? pendingCount.toString() : null,
              ),
              _NavItem(icon: LucideIcons.settings, label: 'Settings', index: 4, selected: selectedIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;
  final String? badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == selected;
    final color = isActive ? AppColors.primary : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            badge != null
                ? Badge(
                    label: Text(badge!, style: const TextStyle(fontSize: 10)),
                    backgroundColor: AppColors.error,
                    child: Icon(icon, size: 20, color: color),
                  )
                : Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.mono(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              width: 24,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DESKTOP SHELL — Sidebar (295px) + Split-pane content area
// ─────────────────────────────────────────────────────────────
class _DesktopShell extends ConsumerWidget {
  final List<Widget> screens;

  const _DesktopShell({required this.screens});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(activeTabProvider);
    final approvalState = ref.watch(approvalProvider);
    final pendingCount = approvalState.count;
    final modelState = ref.watch(modelConfigProvider);
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Main Content (Sidebar + Screen)
          Expanded(
            child: Row(
              children: [
                // Hermes-parity Sidebar
                const HermesSidebar(),

                const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),

                // Main View (Header + Content)
                Expanded(
                  child: Column(
                    children: [
                      // Desktop Header with model/reasoning pickers
                      _DesktopHeader(
                        selectedIndex: selectedIndex,
                        pendingCount: pendingCount,
                        modelState: modelState,
                        chatState: chatState,
                      ),
                      // Screen
                      Expanded(
                        child: IndexedStack(
                          index: selectedIndex,
                          children: screens,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Footer Status Bar
          const HermesStatusBar(),
        ],
      ),
    );
  }
}

class _DesktopHeader extends ConsumerWidget {
  final int selectedIndex;
  final int pendingCount;
  final ModelConfigState modelState;
  final ChatState chatState;

  const _DesktopHeader({
    required this.selectedIndex,
    required this.pendingCount,
    required this.modelState,
    required this.chatState,
  });

  static const _tabLabels = ['CHAT', 'SESSIONS', 'PROJECTS', 'APPROVALS', 'SETTINGS'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChat = selectedIndex == 0;
    final activeModel = modelState.config.activeModel;
    final reasoningEffort = modelState.config.reasoningEffort;
    final activeTab = chatState.activeTab;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Brand Logo Glyph
          Container(
            padding: const EdgeInsets.all(5),
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: AppSpacing.roundedSm,
              border: Border.all(color: AppColors.primary.withAlpha(100)),
            ),
            child: const Icon(LucideIcons.zap, size: 14, color: AppColors.primary),
          ),

          // Page / Session Title
          if (isChat)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                activeTab.title,
                style: AppTypography.mono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(
              _tabLabels[selectedIndex],
              style: AppTypography.mono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),

          const SizedBox(width: 12),

          // Chat header pills (model + reasoning)
          if (isChat) ...[
            const SizedBox(width: 4),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
            // Model Pill
            InkWell(
              onTap: () => _showModelSheet(context, ref),
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

            // Reasoning Pill
            InkWell(
              onTap: () => _showReasoningSheet(context, ref),
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
                      reasoningEffort.toUpperCase(),
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
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // Pending Approvals badge (desktop)
          if (pendingCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(40),
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(color: AppColors.error.withAlpha(120)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.shieldAlert, size: 12, color: AppColors.error),
                  const SizedBox(width: 5),
                  Text(
                    '$pendingCount APPROVAL${pendingCount > 1 ? 'S' : ''}',
                    style: AppTypography.mono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Account Badge Pill
          Builder(
            builder: (ctx) {
              final activeAccount = ref.watch(accountProvider).activeAccount;
              if (activeAccount == null) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: InkWell(
                  onTap: () {
                    AppHaptics.light();
                    AccountSwitcherDialog.show(context);
                  },
                  borderRadius: AppSpacing.roundedSm,
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
                        const Icon(LucideIcons.server, size: 12, color: AppColors.primary),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Text(
                            activeAccount.name,
                            style: AppTypography.mono(fontSize: 11, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(LucideIcons.chevronDown, size: 10, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Connection Pill (always right side)
          const ConnectionPill(),
        ],
      ),
    );
  }

  void _showModelSheet(BuildContext context, WidgetRef ref) {
    AppHaptics.light();
    final allModels = ref.read(modelConfigProvider).config.allAvailableModels;
    final currentActive = ref.read(modelConfigProvider).config.activeModel;

    showDialog(
      context: context,
      builder: (ctx) => _ModelSheet(allModels: allModels, currentActive: currentActive),
    );
  }

  void _showReasoningSheet(BuildContext context, WidgetRef ref) {
    AppHaptics.light();
    final current = ref.read(modelConfigProvider).config.reasoningEffort;
    final model = ref.read(modelConfigProvider).config.activeModel;

    showDialog(
      context: context,
      builder: (ctx) => _ReasoningSheet(currentEffort: current, model: model),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// MODEL PICKER SHEET / DIALOG (shared between mobile & desktop)
// ─────────────────────────────────────────────────────────────
class _ModelSheet extends ConsumerStatefulWidget {
  final List<String> allModels;
  final String currentActive;

  const _ModelSheet({required this.allModels, required this.currentActive});

  @override
  ConsumerState<_ModelSheet> createState() => _ModelSheetState();
}

class _ModelSheetState extends ConsumerState<_ModelSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentActive;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    final content = Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
        maxWidth: isDesktop ? 420 : double.infinity,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          Row(
            children: [
              const Icon(LucideIcons.cpu, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Select Active Model', style: AppTypography.textTheme.titleMedium),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 15),
                tooltip: 'Sync from daemon',
                onPressed: () async {
                  await ref.read(modelConfigProvider.notifier).fetchModelOptions();
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Live models from your Hermes daemon:',
            style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: widget.allModels.isEmpty
                ? Center(
                    child: Text(
                      'No models. Check daemon connection.',
                      style: AppTypography.mono(fontSize: 12, color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.allModels.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (ctx, i) {
                      final model = widget.allModels[i];
                      final isSelected = model == _selected;

                      return InkWell(
                        onTap: () {
                          setState(() => _selected = model);
                          Navigator.of(context).pop();
                          ref.read(modelConfigProvider.notifier).setModel(model);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  model,
                                  style: AppTypography.mono(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(LucideIcons.check, size: 14, color: AppColors.primary),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: BorderSide(color: AppColors.border),
        ),
        child: content,
      );
    }

    return content;
  }
}

// ─────────────────────────────────────────────────────────────
// REASONING PICKER SHEET / DIALOG
// ─────────────────────────────────────────────────────────────
class _ReasoningSheet extends ConsumerWidget {
  final String currentEffort;
  final String model;

  const _ReasoningSheet({required this.currentEffort, required this.model});

  static const _levels = [
    {'level': 'none', 'label': 'None', 'desc': 'No reasoning chain — fastest response.'},
    {'level': 'low', 'label': 'Low', 'desc': 'Light deliberation for quick tasks.'},
    {'level': 'medium', 'label': 'Medium', 'desc': 'Balanced for typical agentic tasks.'},
    {'level': 'high', 'label': 'High (Recommended)', 'desc': 'Deep self-correction for complex work.'},
    {'level': 'ultra', 'label': 'Ultra', 'desc': 'Maximum deliberation budget.'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface,
      constraints: BoxConstraints(
        maxWidth: isDesktop ? 400 : double.infinity,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          Row(
            children: [
              const Icon(LucideIcons.brain, size: 16, color: AppColors.thinking),
              const SizedBox(width: 8),
              Text('Reasoning Effort', style: AppTypography.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Deliberation budget for $model',
            style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          ..._levels.map((opt) {
            final level = opt['level']!;
            final isSelected = level == currentEffort;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceHover : AppColors.background,
                borderRadius: AppSpacing.roundedSm,
                border: Border.all(
                  color: isSelected ? AppColors.thinking : AppColors.border,
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(modelConfigProvider.notifier).setModel(
                        ref.read(modelConfigProvider).config.activeModel,
                        reasoningEffort: level,
                      );
                },
                borderRadius: AppSpacing.roundedSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['label']!,
                            style: AppTypography.mono(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? AppColors.thinking : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            opt['desc']!,
                            style: AppTypography.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(LucideIcons.check, size: 14, color: AppColors.thinking),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
          side: BorderSide(color: AppColors.border),
        ),
        child: content,
      );
    }
    return content;
  }
}
