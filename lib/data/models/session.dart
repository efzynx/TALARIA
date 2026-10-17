class HermesSession {
  final String id;
  final String title;
  final String? project;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;

  const HermesSession({
    required this.id,
    required this.title,
    this.project,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
  });

  factory HermesSession.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is num) {
        return DateTime.fromMillisecondsSinceEpoch((val * 1000).toInt());
      }
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final createdAt = parseDate(json['created_at'] ?? json['started_at']);
    final updatedAt = parseDate(json['updated_at'] ?? json['started_at']);

    return HermesSession(
      id: json['id'] as String? ?? json['session_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Session',
      project: json['project'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messageCount: json['message_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (project != null) 'project': project,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'message_count': messageCount,
      };
}
