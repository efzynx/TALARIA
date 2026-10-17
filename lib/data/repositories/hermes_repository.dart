import '../../core/network/json_rpc_client.dart';
import '../models/config_item.dart';
import '../models/project.dart';
import '../models/session.dart';

class HermesRepository {
  final JsonRpcClient _client;

  HermesRepository(this._client);

  // --- SESSIONS ---
  Future<List<HermesSession>> listSessions() async {
    final response = await _client.call('session.list');
    if (response is List) {
      return response
          .map((item) => HermesSession.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else if (response is Map && response['sessions'] is List) {
      return (response['sessions'] as List)
          .map((item) => HermesSession.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  Future<HermesSession> createSession({
    String? title,
    String? cwd,
    String? project,
  }) async {
    final response = await _client.call('session.create', {
      if (title != null) 'title': title,
      if (cwd != null) 'cwd': cwd,
      if (cwd != null) 'cwd_explicit': true,
    });
    return HermesSession.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Map<String, dynamic>> resumeSession(String sessionId) async {
    final response = await _client.call('session.resume', {
      'session_id': sessionId,
    });
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.call('session.delete', {'session_id': sessionId});
  }

  // --- PROMPTS ---
  Future<dynamic> submitPrompt(String text, {required String sessionId}) async {
    return await _client.call('prompt.submit', {
      'session_id': sessionId,
      'text': text,
    });
  }

  // --- APPROVALS ---
  Future<void> respondApproval(String approvalId, String decision) async {
    // decision: 'once', 'session', 'deny'
    await _client.call('approval.respond', {
      'approval_id': approvalId,
      'decision': decision,
    });
  }

  // --- PROJECTS ---
  Future<List<HermesProject>> listProjects() async {
    final response = await _client.call('projects.list');
    if (response is Map && response['projects'] is List) {
      final activeId = response['active_id'] as String?;
      return (response['projects'] as List)
          .map((item) =>
              HermesProject.fromJson(Map<String, dynamic>.from(item as Map), activeId: activeId))
          .toList();
    } else if (response is List) {
      return response
          .map((item) => HermesProject.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  Future<void> setActiveProject(String projectId) async {
    await _client.call('projects.set_active', {'id': projectId});
  }

  Future<HermesProject> createProject(String name, String path) async {
    final response = await _client.call('projects.create', {
      'name': name,
      'path': path,
    });
    return HermesProject.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Retrieves the unified project tree from daemon (projects.tree)
  /// Uses a high previewLimit (default 200) so all session history per project is returned.
  Future<Map<String, dynamic>> getProjectsTree({
    int previewLimit = 200,
    int sessionLimit = 2000,
  }) async {
    try {
      final response = await _client.call('projects.tree', {
        'preview_limit': previewLimit,
        'session_limit': sessionLimit,
      });
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {}
    return {};
  }

  /// Retrieves fully hydrated sessions for a specific project
  Future<Map<String, dynamic>> getProjectSessions(String projectId) async {
    try {
      final response = await _client.call('projects.project_sessions', {
        'project_id': projectId,
      });
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
    } catch (_) {}
    return {};
  }

  /// Retrieves the roster of agent profiles / bots from daemon (profiles.list)
  Future<List<Map<String, dynamic>>> listProfiles() async {
    try {
      final response = await _client.call('profiles.list', {'include_sessions': true});
      if (response is Map && response['profiles'] is List) {
        return (response['profiles'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // --- MODELS & CONFIG ---
  Future<HermesConfig> getModelOptions() async {
    try {
      final response = await _client.call('model.options', {});
      if (response is Map) {
        return HermesConfig.fromModelOptions(Map<String, dynamic>.from(response));
      }
    } catch (_) {}
    return const HermesConfig();
  }

  Future<void> setModel(String model, {String? reasoningEffort}) async {
    await _client.call('model.options', {
      'model': model,
      if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
    });
  }

  Future<HermesConfig> getConfig() async {
    final response = await _client.call('config.get');
    if (response is Map) {
      return HermesConfig.fromJson(Map<String, dynamic>.from(response));
    }
    return const HermesConfig();
  }

  Future<void> setConfig(String key, dynamic value) async {
    await _client.call('config.set', {'key': key, 'value': value});
  }

  Future<List<String>> listTools() async {
    final response = await _client.call('tools.list');
    if (response is List) {
      return response.map((e) => e.toString()).toList();
    }
    return [];
  }

  // --- SKILLS ---
  Future<Map<String, List<String>>> listSkills() async {
    try {
      final response = await _client.call('skills.manage', {'action': 'list'});
      if (response is Map && response['skills'] is Map) {
        final Map<String, dynamic> raw = Map<String, dynamic>.from(response['skills'] as Map);
        final Map<String, List<String>> result = {};
        raw.forEach((key, val) {
          if (val is List) {
            result[key] = val.map((e) => e.toString()).toList();
          }
        });
        return result;
      }
    } catch (_) {}
    return {};
  }
}
