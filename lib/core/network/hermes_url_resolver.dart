import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Helper untuk menyelesaikan URL koneksi WebSocket ke daemon Hermes Agent.
/// Menangani auto-append path `/api/ws` dan auto-discovery session token dari `GET /`.
abstract class HermesUrlResolver {
  static const Duration probeTimeout = Duration(seconds: 3);

  /// Mengonversi input URL pengguna ke URI WebSocket lengkap `/api/ws?token=...`.
  static Future<Uri> resolve(String input, {String? overrideToken}) async {
    String trimmed = input.trim();
    if (trimmed.isEmpty) {
      trimmed = '127.0.0.1:9119';
    }

    // Tambahkan skema default jika belum ada
    if (!trimmed.startsWith('ws://') &&
        !trimmed.startsWith('wss://') &&
        !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://')) {
      trimmed = 'ws://$trimmed';
    }

    Uri parsed = Uri.parse(trimmed);

    // Tentukan protokol target WebSocket dan HTTP untuk probe
    final isSecure = parsed.scheme == 'wss' || parsed.scheme == 'https';
    final wsScheme = isSecure ? 'wss' : 'ws';
    final httpScheme = isSecure ? 'https' : 'http';

    final host = parsed.host.isNotEmpty ? parsed.host : '127.0.0.1';
    final port = parsed.hasPort ? parsed.port : (isSecure ? 443 : 9119);

    // Pastikan path menunjuk ke `/api/ws` jika masih di root
    String path = parsed.path;
    if (path.isEmpty || path == '/') {
      path = '/api/ws';
    }

    // Periksa apakah token sudah ada di query param
    final queryParams = Map<String, String>.from(parsed.queryParameters);
    String? token = queryParams['token'] ?? overrideToken;

    // Jika token belum tersedia, coba auto-discover dari `GET /`
    if (token == null || token.isEmpty) {
      final discovered = await discoverToken(httpScheme, host, port);
      if (discovered != null && discovered.isNotEmpty) {
        token = discovered;
      }
    }

    if (token != null && token.isNotEmpty) {
      queryParams['token'] = token;
    }

    return Uri(
      scheme: wsScheme,
      host: host,
      port: port,
      path: path,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Melakukan HTTP GET ke root `/` daemon untuk mengekstrak `window.__HERMES_SESSION_TOKEN__`.
  static Future<String?> discoverToken(String scheme, String host, int port) async {
    try {
      final probeUri = Uri(scheme: scheme, host: host, port: port, path: '/');
      final res = await http.get(probeUri).timeout(probeTimeout);

      if (res.statusCode == 200) {
        final match = RegExp(
          r'window\.__HERMES_SESSION_TOKEN__\s*=\s*("(?:\\.|[^"\\])*")',
        ).firstMatch(res.body);

        if (match != null) {
          final rawJson = match.group(1);
          if (rawJson != null) {
            final decoded = jsonDecode(rawJson);
            if (decoded is String && decoded.isNotEmpty) {
              debugPrint('[HermesUrlResolver] Auto-discovered session token for $host:$port');
              return decoded;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[HermesUrlResolver] Probe note: Could not auto-discover token: $e');
    }
    return null;
  }
}
