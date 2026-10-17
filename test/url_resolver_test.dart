import 'package:flutter_test/flutter_test.dart';
import 'package:talaria/core/network/hermes_url_resolver.dart';

void main() {
  group('HermesUrlResolver Tests', () {
    test('Resolves bare input into /api/ws endpoint', () async {
      final uri = await HermesUrlResolver.resolve('127.0.0.1:9119', overrideToken: 'test_token');
      expect(uri.scheme, 'ws');
      expect(uri.host, '127.0.0.1');
      expect(uri.port, 9119);
      expect(uri.path, '/api/ws');
      expect(uri.queryParameters['token'], 'test_token');
    });

    test('Preserves explicit wss:// and custom query parameters', () async {
      final uri = await HermesUrlResolver.resolve('wss://my-hermes.example.com/custom/ws?token=secret123');
      expect(uri.scheme, 'wss');
      expect(uri.host, 'my-hermes.example.com');
      expect(uri.path, '/custom/ws');
      expect(uri.queryParameters['token'], 'secret123');
    });

    test('Auto-discovers session token from live daemon if reachable', () async {
      final uri = await HermesUrlResolver.resolve('ws://127.0.0.1:9119');
      expect(uri.scheme, 'ws');
      expect(uri.host, '127.0.0.1');
      expect(uri.port, 9119);
      expect(uri.path, '/api/ws');
      // If hermes serve is active, token will be populated automatically
      if (uri.queryParameters.containsKey('token')) {
        expect(uri.queryParameters['token']!.isNotEmpty, isTrue);
      }
    });
  });
}
