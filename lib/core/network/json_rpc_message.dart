import 'dart:convert';

/// JSON-RPC 2.0 Error representation.
class JsonRpcError {
  final int code;
  final String message;
  final dynamic data;

  const JsonRpcError({
    required this.code,
    required this.message,
    this.data,
  });

  factory JsonRpcError.fromJson(Map<String, dynamic> json) {
    return JsonRpcError(
      code: json['code'] as int? ?? -32603,
      message: json['message'] as String? ?? 'Internal error',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  @override
  String toString() => 'JsonRpcError($code: $message)';
}

/// JSON-RPC 2.0 Request representation.
class JsonRpcRequest {
  final dynamic id;
  final String method;
  final dynamic params;

  const JsonRpcRequest({
    required this.id,
    required this.method,
    this.params,
  });

  Map<String, dynamic> toJson() => {
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        if (params != null) 'params': params,
      };

  String serialize() => jsonEncode(toJson());
}

/// JSON-RPC 2.0 Response representation.
class JsonRpcResponse {
  final dynamic id;
  final dynamic result;
  final JsonRpcError? error;

  const JsonRpcResponse({
    required this.id,
    this.result,
    this.error,
  });

  bool get isSuccess => error == null;
  bool get isError => error != null;

  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) {
    return JsonRpcResponse(
      id: json['id'],
      result: json['result'],
      error: json['error'] != null
          ? JsonRpcError.fromJson(Map<String, dynamic>.from(json['error'] as Map))
          : null,
    );
  }
}

/// JSON-RPC 2.0 Notification / Event representation (no `id`).
class JsonRpcNotification {
  final String method;
  final dynamic params;

  const JsonRpcNotification({
    required this.method,
    this.params,
  });

  factory JsonRpcNotification.fromJson(Map<String, dynamic> json) {
    return JsonRpcNotification(
      method: json['method'] as String? ?? '',
      params: json['params'],
    );
  }

  Map<String, dynamic> toJson() => {
        'jsonrpc': '2.0',
        'method': method,
        if (params != null) 'params': params,
      };

  String serialize() => jsonEncode(toJson());
}
