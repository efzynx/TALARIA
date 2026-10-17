class ProjectTreeSession {
  final String id;
  final String title;
  final String? preview;
  final int messageCount;
  final DateTime? startedAt;

  const ProjectTreeSession({
    required this.id,
    required this.title,
    this.preview,
    this.messageCount = 0,
    this.startedAt,
  });

  factory ProjectTreeSession.fromJson(Map<String, dynamic> json) {
    DateTime? started;
    final rawStarted = json['started_at'];
    if (rawStarted is num) {
      started = DateTime.fromMillisecondsSinceEpoch((rawStarted * 1000).toInt());
    } else if (rawStarted is String) {
      started = DateTime.tryParse(rawStarted);
    }

    return ProjectTreeSession(
      id: json['id'] as String? ?? json['session_id'] as String? ?? 'sess_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Untitled Session',
      preview: json['preview'] as String?,
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      startedAt: started,
    );
  }
}

class ProjectTreeNode {
  final String id;
  final String label;
  final String? path;
  final String gitBranch;
  final bool isNoProject;
  final int sessionCount;
  final List<ProjectTreeSession> sessions;
  final List<String> sessionIds;

  const ProjectTreeNode({
    required this.id,
    required this.label,
    this.path,
    this.gitBranch = 'main',
    this.isNoProject = false,
    this.sessionCount = 0,
    this.sessions = const [],
    this.sessionIds = const [],
  });

  factory ProjectTreeNode.fromJson(Map<String, dynamic> json) {
    String branch = 'main';
    final repos = json['repos'];
    if (repos is List && repos.isNotEmpty) {
      final firstRepo = repos.first;
      if (firstRepo is Map && firstRepo['groups'] is List) {
        final groups = firstRepo['groups'] as List;
        if (groups.isNotEmpty && groups.first is Map) {
          final groupLabel = groups.first['label'] as String?;
          if (groupLabel != null && groupLabel.isNotEmpty) {
            branch = groupLabel;
          }
        }
      }
    }

    final rawSessions = json['previewSessions'] ?? json['sessions'];
    List<ProjectTreeSession> sessionList = [];
    if (rawSessions is List) {
      sessionList = rawSessions
          .map((s) => ProjectTreeSession.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
    }

    final rawSessionIds = json['sessionIds'];
    List<String> idList = [];
    if (rawSessionIds is List) {
      idList = rawSessionIds.map((e) => e.toString()).toList();
    }

    final isHome = json['isNoProject'] as bool? ?? (json['id'] == '__no_project__');
    final label = isHome ? 'DEFAULT HOME' : (json['label'] as String? ?? 'PROJECT');

    return ProjectTreeNode(
      id: json['id'] as String? ?? '__no_project__',
      label: label,
      path: json['path'] as String?,
      gitBranch: branch,
      isNoProject: isHome,
      sessionCount: (json['sessionCount'] as num?)?.toInt() ?? sessionList.length,
      sessions: sessionList,
      sessionIds: idList,
    );
  }

  ProjectTreeNode copyWith({
    String? id,
    String? label,
    String? path,
    String? gitBranch,
    bool? isNoProject,
    int? sessionCount,
    List<ProjectTreeSession>? sessions,
    List<String>? sessionIds,
  }) {
    return ProjectTreeNode(
      id: id ?? this.id,
      label: label ?? this.label,
      path: path ?? this.path,
      gitBranch: gitBranch ?? this.gitBranch,
      isNoProject: isNoProject ?? this.isNoProject,
      sessionCount: sessionCount ?? this.sessionCount,
      sessions: sessions ?? this.sessions,
      sessionIds: sessionIds ?? this.sessionIds,
    );
  }
}
