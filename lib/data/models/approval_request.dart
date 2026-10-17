enum RiskLevel {
  low,
  medium,
  high,
  danger,
}

class ApprovalRequest {
  final String id;
  final String tool;
  final String command;
  final String? description;
  final RiskLevel riskLevel;
  final String? sessionId;
  final DateTime timestamp;

  const ApprovalRequest({
    required this.id,
    required this.tool,
    required this.command,
    this.description,
    this.riskLevel = RiskLevel.high,
    this.sessionId,
    required this.timestamp,
  });

  factory ApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ApprovalRequest(
      id: json['id'] as String? ?? json['approval_id'] as String? ?? '',
      tool: json['tool'] as String? ?? 'terminal',
      command: json['command'] as String? ?? json['action'] as String? ?? '',
      description: json['description'] as String?,
      riskLevel: _parseRisk(json['risk_level'] ?? json['risk']),
      sessionId: json['session_id'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tool': tool,
        'command': command,
        if (description != null) 'description': description,
        'risk_level': riskLevel.name,
        if (sessionId != null) 'session_id': sessionId,
        'timestamp': timestamp.toIso8601String(),
      };

  static RiskLevel _parseRisk(dynamic raw) {
    switch (raw?.toString().toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'medium':
        return RiskLevel.medium;
      case 'danger':
        return RiskLevel.danger;
      default:
        return RiskLevel.high;
    }
  }
}
