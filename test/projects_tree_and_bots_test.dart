import 'package:flutter_test/flutter_test.dart';
import 'package:talaria/data/models/bot_profile.dart';
import 'package:talaria/data/models/project_tree_node.dart';

void main() {
  group('ProjectTreeNode Tests', () {
    test('parses Home node correctly from projects.tree shape', () {
      final json = {
        'id': '__no_project__',
        'label': 'Home',
        'isNoProject': true,
        'sessionCount': 5,
        'repos': [
          {
            'groups': [
              {'label': 'main'}
            ]
          }
        ],
        'previewSessions': [
          {'id': 's1', 'title': 'First Session', 'message_count': 12},
          {'id': 's2', 'title': 'Second Session', 'message_count': 4},
        ],
      };

      final node = ProjectTreeNode.fromJson(json);
      expect(node.id, '__no_project__');
      expect(node.label, 'DEFAULT HOME');
      expect(node.isNoProject, isTrue);
      expect(node.gitBranch, 'main');
      expect(node.sessions.length, 2);
      expect(node.sessions.first.title, 'First Session');
    });

    test('parses project node correctly from projects.tree shape', () {
      final json = {
        'id': 'p_3ae1abbe',
        'label': 'kepkat',
        'path': '/home/efzyn/reverse-project/kepkat',
        'sessionCount': 1,
        'repos': [
          {
            'groups': [
              {'label': 'dev-branch'}
            ]
          }
        ],
        'previewSessions': [
          {'id': 's_kepkat', 'title': 'Clone CapCut desktop', 'message_count': 589},
        ],
      };

      final node = ProjectTreeNode.fromJson(json);
      expect(node.id, 'p_3ae1abbe');
      expect(node.label, 'kepkat');
      expect(node.isNoProject, isFalse);
      expect(node.gitBranch, 'dev-branch');
      expect(node.sessions.length, 1);
    });
  });

  group('BotProfile Tests', () {
    test('defaultFallbackBots returns all core specialist agents', () {
      final bots = BotProfile.defaultFallbackBots();
      expect(bots.length, 7);

      final names = bots.map((b) => b.name).toList();
      expect(names, containsAll(['default', 'pixel', 'forge', 'helm', 'atlas', 'sentry', 'ian']));

      final pixel = bots.firstWhere((b) => b.name == 'pixel');
      expect(pixel.displayName, 'Pixel');
      expect(pixel.badgeLetter, 'P');
      expect(pixel.description, contains('Frontend'));

      final forge = bots.firstWhere((b) => b.name == 'forge');
      expect(forge.badgeLetter, 'F');
      expect(forge.description, contains('Backend'));
    });

    test('BotProfile.fromRow parses live daemon profile row', () {
      final row = {
        'name': 'pixel',
        'display_name': 'Pixel UI Master',
        'description': 'Mobile and Desktop UI wizard',
        'model': 'AG-gemini',
        'provider': 'custom:9router',
        'skill_count': 24,
        'is_default': false,
        'last_session': {'title': 'Design Talaria UI'},
      };

      final bot = BotProfile.fromRow(row);
      expect(bot.name, 'pixel');
      expect(bot.displayName, 'Pixel UI Master');
      expect(bot.model, 'AG-gemini');
      expect(bot.skillCount, 24);
      expect(bot.lastSessionTitle, 'Design Talaria UI');
    });
  });
}
