import 'package:flutter_test/flutter_test.dart';
import 'package:talaria/core/network/connection_status.dart';
import 'package:talaria/core/network/hermes_auth_service.dart';
import 'package:talaria/data/models/hermes_account.dart';

void main() {
  group('HermesAccount Model Tests', () {
    test('HermesAccount serializes to and from JSON correctly', () {
      final now = DateTime.now();
      final account = HermesAccount(
        id: 'acc_test_1',
        name: 'Production VPS',
        serverUrl: 'ws://192.168.1.100:9119',
        username: 'efzyn',
        password: 'secretpassword',
        token: 'token_sample_123',
        refreshToken: 'rt_sample_456',
        authProvider: 'basic',
        isActive: true,
        createdAt: now,
        lastUsedAt: now,
      );

      final json = account.toJson();
      expect(json['id'], 'acc_test_1');
      expect(json['name'], 'Production VPS');
      expect(json['server_url'], 'ws://192.168.1.100:9119');
      expect(json['username'], 'efzyn');
      expect(json['token'], 'token_sample_123');
      expect(json['is_active'], isTrue);

      final deserialized = HermesAccount.fromJson(json);
      expect(deserialized.id, account.id);
      expect(deserialized.name, account.name);
      expect(deserialized.serverUrl, account.serverUrl);
      expect(deserialized.username, account.username);
      expect(deserialized.token, account.token);
      expect(deserialized.refreshToken, account.refreshToken);
      expect(deserialized.hasToken, isTrue);
      expect(deserialized.hasCredentials, isTrue);
      expect(deserialized.displaySubtitle, 'efzyn @ ws://192.168.1.100:9119');
    });

    test('HermesAccount list serialization and deserialization', () {
      final acc1 = HermesAccount(
        id: 'a1',
        name: 'Local',
        serverUrl: 'ws://127.0.0.1:9119',
        isActive: true,
        createdAt: DateTime.now(),
      );
      final acc2 = HermesAccount(
        id: 'a2',
        name: '0.0.0.0 Bind',
        serverUrl: 'ws://0.0.0.0:9119',
        username: 'efzyn',
        isActive: false,
        createdAt: DateTime.now(),
      );

      final jsonListStr = HermesAccount.listToJson([acc1, acc2]);
      final loaded = HermesAccount.listFromJson(jsonListStr);

      expect(loaded.length, 2);
      expect(loaded[0].name, 'Local');
      expect(loaded[0].isActive, isTrue);
      expect(loaded[1].name, '0.0.0.0 Bind');
      expect(loaded[1].username, 'efzyn');
      expect(loaded[1].isActive, isFalse);
    });
  });

  group('HermesAuthService Tests', () {
    test('toHttpBase correctly transforms various URL inputs', () {
      expect(HermesAuthService.toHttpBase('ws://127.0.0.1:9119'), 'http://127.0.0.1:9119');
      expect(HermesAuthService.toHttpBase('wss://hermes.example.com'), 'https://hermes.example.com:443');
      expect(HermesAuthService.toHttpBase('0.0.0.0:9119'), 'http://0.0.0.0:9119');
      expect(HermesAuthService.toHttpBase('http://localhost:9119/api/ws'), 'http://localhost:9119');
    });

    test('extractTokenFromSetCookie parses various cookie formats', () {
      const cookie1 = 'hermes_session_at=abc123token; Max-Age=43200; Path=/; HttpOnly; SameSite=Lax';
      expect(HermesAuthService.extractTokenFromSetCookie(cookie1), 'abc123token');

      const cookieSecure = '__Secure-hermes_session_at=secToken999; Path=/; Secure; HttpOnly';
      expect(HermesAuthService.extractTokenFromSetCookie(cookieSecure), 'secToken999');

      const cookieHost = '__Host-hermes_session_at=hostToken888; Path=/; Secure; HttpOnly';
      expect(HermesAuthService.extractTokenFromSetCookie(cookieHost), 'hostToken888');

      const cookieCombined =
          'hermes_session_at=my_at_token; Path=/, hermes_session_rt=my_rt_token; Path=/';
      expect(HermesAuthService.extractTokenFromSetCookie(cookieCombined), 'my_at_token');
      expect(HermesAuthService.extractRefreshTokenFromSetCookie(cookieCombined), 'my_rt_token');
    });

    test('ConnectionStatus contains unauthorized enum and label', () {
      expect(ConnectionStatus.unauthorized.isUnauthorized, isTrue);
      expect(ConnectionStatus.unauthorized.label, 'Auth Required');
      expect(ConnectionStatus.connected.isUnauthorized, isFalse);
    });
  });
}
