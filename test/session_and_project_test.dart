import 'package:flutter_test/flutter_test.dart';
import 'package:talaria/data/models/config_item.dart';
import 'package:talaria/data/models/project.dart';
import 'package:talaria/data/models/session.dart';

void main() {
  group('Models & State Contract Tests', () {
    test('HermesProject parses primary_path and active_id correctly', () {
      final json = {
        'id': 'p_2b60d0df',
        'name': 'talaria',
        'slug': 'talaria',
        'primary_path': '/home/efzyn/Project/talaria',
        'folders': [
          {'path': '/home/efzyn/Project/talaria', 'is_primary': true}
        ]
      };

      final project = HermesProject.fromJson(json, activeId: 'p_2b60d0df');
      expect(project.id, 'p_2b60d0df');
      expect(project.name, 'talaria');
      expect(project.path, '/home/efzyn/Project/talaria');
      expect(project.isActive, isTrue);

      final inactiveProject = HermesProject.fromJson(json, activeId: 'other_id');
      expect(inactiveProject.isActive, isFalse);
    });

    test('HermesSession parses started_at epoch timestamp correctly', () {
      final json = {
        'id': '20261017_155333_629a9d',
        'title': 'Inisialisasi project Flutter Talaria',
        'started_at': 1792227223.12,
        'message_count': 280,
      };

      final session = HermesSession.fromJson(json);
      expect(session.id, '20261017_155333_629a9d');
      expect(session.title, 'Inisialisasi project Flutter Talaria');
      expect(session.messageCount, 280);
      expect(session.createdAt.year, greaterThan(2020));
    });

    test('HermesConfig parses real providers and models payload from model.options', () {
      final json = {
        'model': 'AG-gemini',
        'provider': 'custom:9router',
        'providers': [
          {
            'slug': 'custom:9router',
            'name': '9router',
            'models': ['AG-gemini', 'AG-claude', 'power-agent'],
          },
          {
            'slug': 'nous',
            'name': 'Nous Portal',
            'models': ['anthropic/claude-opus-5'],
          }
        ]
      };

      final config = HermesConfig.fromModelOptions(json, reasoning: 'ultra');
      expect(config.activeModel, 'AG-gemini');
      expect(config.activeProvider, 'custom:9router');
      expect(config.reasoningEffort, 'ultra');
      expect(config.allAvailableModels, contains('AG-gemini'));
      expect(config.allAvailableModels, contains('AG-claude'));
      expect(config.allAvailableModels, contains('anthropic/claude-opus-5'));
    });
  });
}
