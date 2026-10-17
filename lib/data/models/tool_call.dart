enum ToolExecutionStatus {
  running,
  done,
  error,
}

class ToolCall {
  final String id;
  final String tool;
  final Map<String, dynamic> args;
  final String? output;
  final ToolExecutionStatus status;
  final int? durationMs;

  const ToolCall({
    required this.id,
    required this.tool,
    this.args = const {},
    this.output,
    this.status = ToolExecutionStatus.running,
    this.durationMs,
  });

  ToolCall copyWith({
    String? id,
    String? tool,
    Map<String, dynamic>? args,
    String? output,
    ToolExecutionStatus? status,
    int? durationMs,
  }) {
    return ToolCall(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      args: args ?? this.args,
      output: output ?? this.output,
      status: status ?? this.status,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String? ?? '',
      tool: json['tool'] as String? ?? 'unknown',
      args: json['args'] != null ? Map<String, dynamic>.from(json['args'] as Map) : {},
      output: json['output'] as String?,
      status: _parseStatus(json['status']),
      durationMs: json['duration_ms'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tool': tool,
        'args': args,
        if (output != null) 'output': output,
        'status': status.name,
        if (durationMs != null) 'duration_ms': durationMs,
      };

  static ToolExecutionStatus _parseStatus(dynamic raw) {
    switch (raw) {
      case 'done':
      case 'success':
        return ToolExecutionStatus.done;
      case 'error':
      case 'failed':
        return ToolExecutionStatus.error;
      default:
        return ToolExecutionStatus.running;
    }
  }
}
