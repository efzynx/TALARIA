import 'package:flutter_test/flutter_test.dart';
import 'package:talaria/data/models/slash_command.dart';

void main() {
  group('Slash Command Matching Tests', () {
    test('SlashCommandItem matches prefixes and keywords', () {
      const modelCmd = SlashCommandItem(
        trigger: '/model',
        title: 'Switch Active Model',
        description: 'Change the LLM model (e.g. /model AG-gemini)',
        type: SlashCommandType.model,
      );

      expect(modelCmd.matches('/'), isTrue);
      expect(modelCmd.matches('/m'), isTrue);
      expect(modelCmd.matches('/mod'), isTrue);
      expect(modelCmd.matches('model'), isTrue);
      expect(modelCmd.matches('switch'), isTrue);
      expect(modelCmd.matches('/reasoning'), isFalse);
    });

    test('Skill items match triggers like /reverse-engineer-anything and /no-ai-slop', () {
      const reverseSkill = SlashCommandItem(
        trigger: '/reverse-engineer-anything',
        title: 'reverse-engineer-anything',
        description: 'Skill in general',
        type: SlashCommandType.skill,
      );

      const noAiSlopSkill = SlashCommandItem(
        trigger: '/no-ai-slop',
        title: 'no-ai-slop',
        description: 'Skill in openclaw-imports',
        type: SlashCommandType.skill,
      );

      expect(reverseSkill.matches('/rev'), isTrue);
      expect(reverseSkill.matches('/reverse-engineer-anything'), isTrue);
      expect(noAiSlopSkill.matches('/no-'), isTrue);
      expect(noAiSlopSkill.matches('/no-ai-slop'), isTrue);
      expect(reverseSkill.matches('/no-ai-slop'), isFalse);
    });
  });
}
