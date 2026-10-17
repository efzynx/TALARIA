import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/connection_status.dart';
import '../core/network/json_rpc_client.dart';
import '../core/network/json_rpc_message.dart';
import '../data/repositories/hermes_repository.dart';

class ConnectionStateData {
  final ConnectionStatus status;
  final String serverUrl;
  final String? token;
  final String? resolvedUrl;
  final int? latencyMs;
  final String? errorMessage;

  const ConnectionStateData({
    required this.status,
    required this.serverUrl,
    this.token,
    this.resolvedUrl,
    this.latencyMs,
    this.errorMessage,
  });

  bool get isUnauthorized => status == ConnectionStatus.unauthorized;
  bool get isConnected => status == ConnectionStatus.connected;

  ConnectionStateData copyWith({
    ConnectionStatus? status,
    String? serverUrl,
    String? token,
    String? resolvedUrl,
    int? latencyMs,
    String? errorMessage,
  }) {
    return ConnectionStateData(
      status: status ?? this.status,
      serverUrl: serverUrl ?? this.serverUrl,
      token: token ?? this.token,
      resolvedUrl: resolvedUrl ?? this.resolvedUrl,
      latencyMs: latencyMs ?? this.latencyMs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ConnectionNotifier extends StateNotifier<ConnectionStateData> {
  static const String _prefServerUrlKey = 'talaria_server_url';
  static const String _prefTokenKey = 'talaria_auth_token';

  final JsonRpcClient _client = JsonRpcClient();

  StreamSubscription? _statusSub;
  StreamSubscription? _latencySub;

  ConnectionNotifier()
      : super(const ConnectionStateData(
          status: ConnectionStatus.disconnected,
          serverUrl: JsonRpcClient.defaultUrl,
        )) {
    _init();
  }

  JsonRpcClient get client => _client;

  Future<void> _init() async {
    // Muat konfigurasi URL tersimpan dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_prefServerUrlKey) ?? JsonRpcClient.defaultUrl;
    final savedToken = prefs.getString(_prefTokenKey);

    state = state.copyWith(
      serverUrl: savedUrl,
      token: savedToken,
    );
    _client.updateCredentials(url: savedUrl, token: savedToken);

    _statusSub = _client.statusStream.listen((status) {
      state = state.copyWith(
        status: status,
        resolvedUrl: _client.activeUri?.toString(),
      );
    });

    _latencySub = _client.latencyStream.listen((latency) {
      state = state.copyWith(latencyMs: latency);
    });

    // Mulai koneksi awal
    await _client.connect();
  }

  Future<void> reconnect() async {
    await _client.connect();
  }

  void disconnect() {
    _client.disconnect();
  }

  /// Updates server endpoint and authentication token atomically
  Future<void> updateConnection({required String url, String? token}) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefServerUrlKey, trimmed);
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_prefTokenKey, token);
    } else {
      await prefs.remove(_prefTokenKey);
    }

    state = state.copyWith(
      serverUrl: trimmed,
      token: token,
    );
    _client.updateCredentials(url: trimmed, token: token);
  }

  Future<void> updateServerUrl(String newUrl) async {
    await updateConnection(url: newUrl, token: state.token);
  }

  Future<void> updateToken(String? token) async {
    await updateConnection(url: state.serverUrl, token: token);
  }

  Future<T> call<T>(String method, [dynamic params, Duration timeout = const Duration(seconds: 15)]) {
    return _client.call<T>(method, params, timeout);
  }

  Stream<JsonRpcNotification> get notificationStream => _client.notificationStream;

  @override
  void dispose() {
    _statusSub?.cancel();
    _latencySub?.cancel();
    _client.dispose();
    super.dispose();
  }
}

final connectionProvider =
    StateNotifierProvider<ConnectionNotifier, ConnectionStateData>((ref) {
  return ConnectionNotifier();
});

final clientProvider = Provider<JsonRpcClient>((ref) {
  final notifier = ref.watch(connectionProvider.notifier);
  return notifier.client;
});

final hermesRepositoryProvider = Provider<HermesRepository>((ref) {
  final client = ref.watch(clientProvider);
  return HermesRepository(client);
});
