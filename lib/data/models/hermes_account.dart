import 'dart:convert';

/// Represents a configured Hermes Agent account or connection profile.
/// Supports switching between multiple server endpoints (e.g. Localhost, VPS, 0.0.0.0, LAN)
/// and storing credentials (username, password, access token, refresh token).
class HermesAccount {
  final String id;
  final String name;
  final String serverUrl;
  final String? username;
  final String? password;
  final String? token;
  final String? refreshToken;
  final String authProvider;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  const HermesAccount({
    required this.id,
    required this.name,
    required this.serverUrl,
    this.username,
    this.password,
    this.token,
    this.refreshToken,
    this.authProvider = 'basic',
    this.isActive = false,
    required this.createdAt,
    this.lastUsedAt,
  });

  bool get hasToken => token != null && token!.isNotEmpty;
  bool get hasCredentials => username != null && username!.isNotEmpty;

  /// Friendly subtitle describing identity or URL
  String get displaySubtitle {
    if (username != null && username!.isNotEmpty) {
      return '$username @ $serverUrl';
    }
    return serverUrl;
  }

  HermesAccount copyWith({
    String? id,
    String? name,
    String? serverUrl,
    String? username,
    String? password,
    String? token,
    String? refreshToken,
    String? authProvider,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return HermesAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      authProvider: authProvider ?? this.authProvider,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'server_url': serverUrl,
      'username': username,
      'password': password,
      'token': token,
      'refresh_token': refreshToken,
      'auth_provider': authProvider,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }

  factory HermesAccount.fromJson(Map<String, dynamic> json) {
    return HermesAccount(
      id: json['id'] as String? ?? 'acc_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Hermes Server',
      serverUrl: json['server_url'] as String? ?? 'ws://127.0.0.1:9119',
      username: json['username'] as String?,
      password: json['password'] as String?,
      token: json['token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      authProvider: json['auth_provider'] as String? ?? 'basic',
      isActive: json['is_active'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.tryParse(json['last_used_at'] as String)
          : null,
    );
  }

  static List<HermesAccount> listFromJson(String jsonStr) {
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map((item) => HermesAccount.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<HermesAccount> accounts) {
    return jsonEncode(accounts.map((a) => a.toJson()).toList());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HermesAccount &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          serverUrl == other.serverUrl &&
          username == other.username &&
          token == other.token &&
          isActive == other.isActive;

  @override
  int get hashCode => id.hashCode ^ serverUrl.hashCode ^ isActive.hashCode;
}
