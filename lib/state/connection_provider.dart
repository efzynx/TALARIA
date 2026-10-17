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
  final int? latencyMs;
  final String? errorMessage;

  const ConnectionStateData({
    required this.status,
    required this.serverUrl,
    this.latencyMs,
    this.errorMessage,
  });

  ConnectionStateData copyWith({
    ConnectionStatus? status,
    String? serverUrl,
    int? latencyMs,
    String? errorMessage,
  }) {
    return ConnectionStateData(
      status: status ?? this.status,
      serverUrl: serverUrl ?? this.serverUrl,
      latencyMs: latencyMs ?? this.latencyMs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ConnectionNotifier extends StateNotifier<ConnectionStateData> {
  static const String _prefServerUrlKey = 'talaria_server_url';
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

    state = state.copyWith(serverUrl: savedUrl);
    _client.updateServerUrl(savedUrl);

    _statusSub = _client.statusStream.listen((status) {
      state = state.copyWith(status: status);
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

  Future<void> updateServerUrl(String newUrl) async {
    final trimmed = newUrl.trim();
    if (trimmed.isEmpty || trimmed == state.serverUrl) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefServerUrlKey, trimmed);

    state = state.copyWith(serverUrl: trimmed);
    _client.updateServerUrl(trimmed);
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
