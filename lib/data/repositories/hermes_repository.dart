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

  Future<HermesSession> createSession({String? title, String? project}) async {
    final response = await _client.call('session.create', {
      if (title != null) 'title': title,
      if (project != null) 'project': project,
    });
    return HermesSession.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<void> resumeSession(String sessionId) async {
    await _client.call('session.resume', {'session_id': sessionId});
  }

  Future<void> deleteSession(String sessionId) async {
    await _client.call('session.delete', {'session_id': sessionId});
  }

  // --- PROMPTS ---
  Future<dynamic> submitPrompt(String prompt, {String? sessionId}) async {
    return await _client.call('prompt.submit', {
      'prompt': prompt,
      if (sessionId != null) 'session_id': sessionId,
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
    if (response is List) {
      return response
          .map((item) => HermesProject.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else if (response is Map && response['projects'] is List) {
      return (response['projects'] as List)
          .map((item) => HermesProject.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }
    return [];
  }

  Future<void> setActiveProject(String projectPath) async {
    await _client.call('projects.set_active', {'path': projectPath});
  }

  Future<HermesProject> createProject(String name, String path) async {
    final response = await _client.call('projects.create', {
      'name': name,
      'path': path,
    });
    return HermesProject.fromJson(Map<String, dynamic>.from(response as Map));
  }

  // --- CONFIG ---
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
}
