/// Connection status of the WebSocket JSON-RPC client.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

extension ConnectionStatusX on ConnectionStatus {
  bool get isConnected => this == ConnectionStatus.connected;
  bool get isConnecting => this == ConnectionStatus.connecting;
  bool get isReconnecting => this == ConnectionStatus.reconnecting;
  bool get isDisconnected => this == ConnectionStatus.disconnected;

  String get label {
    switch (this) {
      case ConnectionStatus.connected:
        return 'Online';
      case ConnectionStatus.connecting:
        return 'Connecting';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting';
      case ConnectionStatus.disconnected:
        return 'Offline';
    }
  }
}
