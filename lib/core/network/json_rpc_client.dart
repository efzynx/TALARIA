import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'connection_status.dart';
import 'hermes_url_resolver.dart';
import 'json_rpc_message.dart';

/// Client WebSocket JSON-RPC 2.0 untuk daemon hermes serve.
/// Menangani auto-reconnect backoff (1s, 2s, 5s, 10s, 30s) dan heartbeat gateway.ping (30s).
class JsonRpcClient {
  static const String defaultUrl = 'ws://127.0.0.1:9119';
  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const List<Duration> reconnectBackoffs = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  String _serverUrl;
  String? _authToken;
  Uri? _activeUri;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  int _nextId = 1;
  int _reconnectAttempt = 0;
  bool _manuallyDisconnected = false;

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  DateTime? _lastPingSent;
  int? _latencyMs;

  final Map<dynamic, Completer<dynamic>> _pendingRequests = {};

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<JsonRpcNotification> _notificationController =
      StreamController<JsonRpcNotification>.broadcast();
  final StreamController<int?> _latencyController =
      StreamController<int?>.broadcast();

  JsonRpcClient({String serverUrl = defaultUrl}) : _serverUrl = serverUrl;

  // Getters
  String get serverUrl => _serverUrl;
  String? get authToken => _authToken;
  Uri? get activeUri => _activeUri;
  ConnectionStatus get status => _status;
  int? get latencyMs => _latencyMs;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<JsonRpcNotification> get notificationStream => _notificationController.stream;
  Stream<int?> get latencyStream => _latencyController.stream;

  /// Memperbarui URL server dan token lalu menyambung ulang jika berubah
  void updateCredentials({required String url, String? token}) {
    final urlChanged = _serverUrl != url;
    final tokenChanged = _authToken != token;
    _serverUrl = url;
    _authToken = token;

    if (urlChanged || tokenChanged) {
      connect();
    }
  }

  /// Memperbarui URL server dan menyambung ulang jika sedang aktif
  void updateServerUrl(String newUrl) {
    updateCredentials(url: newUrl, token: _authToken);
  }

  /// Memperbarui token autentikasi
  void updateToken(String? token) {
    updateCredentials(url: _serverUrl, token: token);
  }

  /// Memulai koneksi ke server
  Future<void> connect({String? url, String? token}) async {
    if (url != null) {
      _serverUrl = url;
    }
    if (token != null) {
      _authToken = token;
    }

    _manuallyDisconnected = false;
    _cancelReconnectTimer();
    _cleanupChannel();

    _setStatus(_reconnectAttempt > 0
        ? ConnectionStatus.reconnecting
        : ConnectionStatus.connecting);

    try {
      final uri = await HermesUrlResolver.resolve(_serverUrl, overrideToken: _authToken);
      _activeUri = uri;
      debugPrint('[JsonRpcClient] Connecting to WebSocket: $uri');
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;

      _channel = channel;
      _reconnectAttempt = 0;
      _setStatus(ConnectionStatus.connected);

      _channelSubscription = _channel!.stream.listen(
        _onMessageReceived,
        onError: _onChannelError,
        onDone: _onChannelDone,
        cancelOnError: true,
      );

      _startHeartbeat();
      // Langsung lakukan ping awal untuk kalkulasi latency
      _sendPing();
    } catch (e) {
      debugPrint('[JsonRpcClient] Connection error to $_serverUrl (resolved: $_activeUri): $e');
      _cleanupChannel();

      final errStr = e.toString().toLowerCase();
      final isAuthError = errStr.contains('401') ||
          errStr.contains('403') ||
          errStr.contains('unauthorized') ||
          errStr.contains('forbidden') ||
          errStr.contains('authentication');

      if (isAuthError) {
        debugPrint('[JsonRpcClient] Authentication required/rejected for $_serverUrl');
        _setStatus(ConnectionStatus.unauthorized);
        _cancelReconnectTimer();
      } else {
        _handleDisconnect();
      }
    }
  }

  /// Memutus koneksi secara manual (tidak memicu auto-reconnect)
  void disconnect() {
    _manuallyDisconnected = true;
    _cancelHeartbeat();
    _cancelReconnectTimer();
    _cleanupChannel();
    _rejectAllPendingRequests('Client disconnected');
    _setStatus(ConnectionStatus.disconnected);
  }

  /// Mengirim request JSON-RPC 2.0 dan menunggu respons
  Future<T> call<T>(
    String method, [
    dynamic params,
    Duration timeout = const Duration(seconds: 15),
  ]) {
    if (_status != ConnectionStatus.connected || _channel == null) {
      return Future.error(
        const JsonRpcError(code: -32000, message: 'WebSocket is not connected'),
      );
    }

    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;

    final request = JsonRpcRequest(id: id, method: method, params: params);

    try {
      _channel!.sink.add(request.serialize());
    } catch (e) {
      _pendingRequests.remove(id);
      return Future.error(
        JsonRpcError(code: -32000, message: 'Failed to send request: $e'),
      );
    }

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pendingRequests.remove(id);
        throw JsonRpcError(code: -32000, message: 'Request timeout for $method');
      },
    ).then((value) => value as T);
  }

  /// Mengirim notification JSON-RPC 2.0 tanpa menunggu balasan (fire and forget)
  void notify(String method, [dynamic params]) {
    if (_status != ConnectionStatus.connected || _channel == null) return;
    try {
      final notification = JsonRpcNotification(method: method, params: params);
      _channel!.sink.add(notification.serialize());
    } catch (e) {
      debugPrint('[JsonRpcClient] Error sending notification: $e');
    }
  }

  void _onMessageReceived(dynamic rawData) {
    try {
      final text = rawData is String ? rawData : utf8.decode(rawData as List<int>);
      final dynamic decoded = jsonDecode(text);

      if (decoded is List) {
        // Batch responses
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _processSingleJsonMessage(item);
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        _processSingleJsonMessage(decoded);
      }
    } catch (e) {
      debugPrint('[JsonRpcClient] Failed to parse incoming message: $e');
    }
  }

  void _processSingleJsonMessage(Map<String, dynamic> data) {
    final id = data['id'];

    if (id != null && _pendingRequests.containsKey(id)) {
      final completer = _pendingRequests.remove(id);
      if (data.containsKey('error') && data['error'] != null) {
        completer?.completeError(
          JsonRpcError.fromJson(Map<String, dynamic>.from(data['error'] as Map)),
        );
      } else {
        completer?.complete(data['result']);
      }
      return;
    }

    // Cek jika response untuk heartbeat ping
    if (id != null && id == 'ping') {
      if (_lastPingSent != null) {
        _latencyMs = DateTime.now().difference(_lastPingSent!).inMilliseconds;
        _latencyController.add(_latencyMs);
      }
      return;
    }

    // Jika bukan response ber-ID atau ID tidak ada, anggap sebagai notification / server event
    if (data.containsKey('method')) {
      final notification = JsonRpcNotification.fromJson(data);
      _notificationController.add(notification);
    }
  }

  void _onChannelError(dynamic error) {
    debugPrint('[JsonRpcClient] Channel error: $error');
    _handleDisconnect();
  }

  void _onChannelDone() {
    debugPrint('[JsonRpcClient] Channel closed');
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _cancelHeartbeat();
    _cleanupChannel();
    _rejectAllPendingRequests('Connection closed');

    if (_manuallyDisconnected) {
      _setStatus(ConnectionStatus.disconnected);
      return;
    }

    if (_status == ConnectionStatus.unauthorized) {
      return;
    }

    _setStatus(ConnectionStatus.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _cancelReconnectTimer();

    final backoffIndex = _reconnectAttempt < reconnectBackoffs.length
        ? _reconnectAttempt
        : reconnectBackoffs.length - 1;
    final delay = reconnectBackoffs[backoffIndex];
    _reconnectAttempt++;

    debugPrint('[JsonRpcClient] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempt)...');

    _reconnectTimer = Timer(delay, () {
      if (!_manuallyDisconnected) {
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _cancelHeartbeat();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) => _sendPing());
  }

  void _sendPing() {
    if (_status != ConnectionStatus.connected || _channel == null) return;
    try {
      _lastPingSent = DateTime.now();
      final pingMsg = jsonEncode({
        'jsonrpc': '2.0',
        'id': 'ping',
        'method': 'gateway.ping',
        'params': {},
      });
      _channel!.sink.add(pingMsg);
    } catch (e) {
      debugPrint('[JsonRpcClient] Failed to send heartbeat ping: $e');
      _handleDisconnect();
    }
  }

  void _cancelHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _cleanupChannel() {
    _channelSubscription?.cancel();
    _channelSubscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void _rejectAllPendingRequests(String reason) {
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          JsonRpcError(code: -32000, message: reason),
        );
      }
    }
    _pendingRequests.clear();
  }

  void _setStatus(ConnectionStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _notificationController.close();
    _latencyController.close();
  }
}
