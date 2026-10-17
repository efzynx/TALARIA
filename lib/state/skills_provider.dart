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

  static const List<SlashCommandItem> defaultSystemCommands = [
    SlashCommandItem(
      trigger: '/model',
      title: 'Switch Active Model',
      description: 'Change the LLM model (e.g. /model AG-gemini)',
      type: SlashCommandType.model,
    ),
    SlashCommandItem(
      trigger: '/reasoning',
      title: 'Set Reasoning Effort',
      description: 'Set effort: none, low, medium, high, ultra',
      type: SlashCommandType.reasoning,
    ),
    SlashCommandItem(
      trigger: '/new',
      title: 'New Session',
      description: 'Start a fresh agent session in current workspace',
      type: SlashCommandType.system,
    ),
    SlashCommandItem(
      trigger: '/clear',
      title: 'Clear Chat Messages',
      description: 'Clear local message history buffer',
      type: SlashCommandType.system,
    ),
    SlashCommandItem(
      trigger: '/skills',
      title: 'List All Skills',
      description: 'View all installed skills categorized by capability',
      type: SlashCommandType.system,
    ),
    SlashCommandItem(
      trigger: '/help',
      title: 'Help & Commands',
      description: 'Display quick reference of commands and actions',
      type: SlashCommandType.system,
    ),
  ];

  SkillsNotifier(this._ref)
      : super(const SkillsState(allSlashCommands: defaultSystemCommands)) {
    _init();
  }

  void _init() {
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

      final List<SlashCommandItem> commandList = [...defaultSystemCommands];

      skillsMap.forEach((category, list) {
        for (final skill in list) {
          final cleanName = skill.contains('/') ? skill.split('/').last : skill;
          commandList.add(
            SlashCommandItem(
              trigger: '/$cleanName',
              title: cleanName,
              description: 'Skill in $category ($skill)',
              type: SlashCommandType.skill,
              category: category,
            ),
          );
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
