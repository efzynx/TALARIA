import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/connection_status.dart';
import '../data/models/slash_command.dart';
import 'connection_provider.dart';

class SkillsState {
  final Map<String, List<String>> categorizedSkills;
  final List<SlashCommandItem> allSlashCommands;
  final bool isLoading;

  const SkillsState({
    this.categorizedSkills = const {},
    this.allSlashCommands = const [],
    this.isLoading = false,
  });

  SkillsState copyWith({
    Map<String, List<String>>? categorizedSkills,
    List<SlashCommandItem>? allSlashCommands,
    bool? isLoading,
  }) {
    return SkillsState(
      categorizedSkills: categorizedSkills ?? this.categorizedSkills,
      allSlashCommands: allSlashCommands ?? this.allSlashCommands,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SkillsNotifier extends StateNotifier<SkillsState> {
  final Ref _ref;

  static const List<SlashCommandItem> coreSystemCommands = [
    SlashCommandItem(
      trigger: '/model',
      title: 'Switch Active Model',
      description: 'Change the active LLM (e.g. /model AG-gemini)',
      type: SlashCommandType.model,
      category: 'system',
    ),
    SlashCommandItem(
      trigger: '/reasoning',
      title: 'Set Reasoning Effort',
      description: 'Set effort: none, low, medium, high, ultra',
      type: SlashCommandType.reasoning,
      category: 'system',
    ),
    SlashCommandItem(
      trigger: '/new',
      title: 'New Session Tab',
      description: 'Open a fresh chat tab with default home or active workspace',
      type: SlashCommandType.system,
      category: 'session',
    ),
    SlashCommandItem(
      trigger: '/clear',
      title: 'Clear Chat Messages',
      description: 'Clear local message history buffer in current tab',
      type: SlashCommandType.system,
      category: 'session',
    ),
    SlashCommandItem(
      trigger: '/skills',
      title: 'List All Installed Skills',
      description: 'View all 100+ skills categorized by capability',
      type: SlashCommandType.system,
      category: 'skills',
    ),
    SlashCommandItem(
      trigger: '/projects',
      title: 'Manage Workspace Projects',
      description: 'List or switch active workspace directory',
      type: SlashCommandType.system,
      category: 'workspace',
    ),
    SlashCommandItem(
      trigger: '/help',
      title: 'Help & Commands Reference',
      description: 'Display quick reference guide for commands and skills',
      type: SlashCommandType.system,
      category: 'system',
    ),
    SlashCommandItem(
      trigger: '/reverse-engineer-anything',
      title: 'reverse-engineer-anything',
      description: 'Reverse engineer native, managed, Electron/JS, packet captures',
      type: SlashCommandType.skill,
      category: 'general',
    ),
    SlashCommandItem(
      trigger: '/no-ai-slop',
      title: 'no-ai-slop',
      description: 'Edit drafts into sharper, human writing without generic AI buzzwords',
      type: SlashCommandType.skill,
      category: 'writing',
    ),
    SlashCommandItem(
      trigger: '/flutter-engineering',
      title: 'flutter-engineering',
      description: 'Multiplatform Flutter engineering (Android, Linux, Windows)',
      type: SlashCommandType.skill,
      category: 'devops',
    ),
    SlashCommandItem(
      trigger: '/frontend-ui-engineering',
      title: 'frontend-ui-engineering',
      description: 'Build production-quality mobile & desktop interfaces',
      type: SlashCommandType.skill,
      category: 'frontend',
    ),
    SlashCommandItem(
      trigger: '/systematic-debugging',
      title: 'systematic-debugging',
      description: '4-phase root cause debugging before touching code',
      type: SlashCommandType.skill,
      category: 'software-development',
    ),
    SlashCommandItem(
      trigger: '/test-driven-development',
      title: 'test-driven-development',
      description: 'TDD: enforce RED-GREEN-REFACTOR cycle',
      type: SlashCommandType.skill,
      category: 'software-development',
    ),
    SlashCommandItem(
      trigger: '/anti-ai-ui-patterns',
      title: 'anti-ai-ui-patterns',
      description: 'Strip AI-generated UI clichés for organic editorial design',
      type: SlashCommandType.skill,
      category: 'creative',
    ),
    SlashCommandItem(
      trigger: '/impeccable',
      title: 'impeccable',
      description: 'Design, critique, shape, and refine web/mobile interfaces',
      type: SlashCommandType.skill,
      category: 'creative',
    ),
    SlashCommandItem(
      trigger: '/seo',
      title: 'seo',
      description: 'Search engine visibility, technical audits, ranking optimization',
      type: SlashCommandType.skill,
      category: 'marketing',
    ),
    SlashCommandItem(
      trigger: '/vps-deployment',
      title: 'vps-deployment',
      description: 'Deploy apps or Compose stacks to a VPS via SSH',
      type: SlashCommandType.skill,
      category: 'devops',
    ),
    SlashCommandItem(
      trigger: '/grounded-citations',
      title: 'grounded-citations',
      description: 'Ground answers and documents in cited, verifiable sources',
      type: SlashCommandType.skill,
      category: 'research',
    ),
  ];

  SkillsNotifier(this._ref)
      : super(const SkillsState(allSlashCommands: coreSystemCommands)) {
    _init();
  }

  void _init() {
    // If already connected when constructed, fetch immediately
    final currentStatus = _ref.read(connectionProvider).status;
    if (currentStatus.isConnected) {
      fetchSkills();
    }

    _ref.listen(connectionProvider, (prev, next) {
      if (next.status.isConnected && (prev == null || !prev.status.isConnected)) {
        fetchSkills();
      }
    });
  }

  Future<void> fetchSkills() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(hermesRepositoryProvider);
      final skillsMap = await repo.listSkills();

      final List<SlashCommandItem> commandList = [...coreSystemCommands];
      final existingTriggers = commandList.map((c) => c.trigger).toSet();

      skillsMap.forEach((category, list) {
        for (final skill in list) {
          final cleanName = skill.contains('/') ? skill.split('/').last : skill;
          final trigger = '/$cleanName';

          if (!existingTriggers.contains(trigger)) {
            existingTriggers.add(trigger);
            commandList.add(
              SlashCommandItem(
                trigger: trigger,
                title: cleanName,
                description: 'Skill in $category ($skill)',
                type: SlashCommandType.skill,
                category: category,
              ),
            );
          }
        }
      });

      state = state.copyWith(
        categorizedSkills: skillsMap,
        allSlashCommands: commandList,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  List<SlashCommandItem> search(String query) {
    if (query.isEmpty || query == '/') {
      return state.allSlashCommands;
    }
    return state.allSlashCommands.where((cmd) => cmd.matches(query)).toList();
  }
}

final skillsProvider = StateNotifierProvider<SkillsNotifier, SkillsState>((ref) {
  return SkillsNotifier(ref);
});
