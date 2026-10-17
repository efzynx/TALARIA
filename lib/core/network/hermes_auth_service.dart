import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthRequirementResult {
  final bool requiresAuth;
  final bool supportsPassword;
  final List<String> providers;
  final String? preferredProvider;
  final String? message;

  const AuthRequirementResult({
    required this.requiresAuth,
    required this.supportsPassword,
    this.providers = const [],
    this.preferredProvider,
    this.message,
  });
}

class AuthLoginResult {
  final bool success;
  final String? token;
  final String? refreshToken;
  final String? userId;
  final String? displayName;
  final String? email;
  final String? errorMessage;

  const AuthLoginResult({
    required this.success,
    this.token,
    this.refreshToken,
    this.userId,
    this.displayName,
    this.email,
    this.errorMessage,
  });

  factory AuthLoginResult.failure(String message) {
    return AuthLoginResult(success: false, errorMessage: message);
  }
}

class HermesAuthService {
  static const Duration requestTimeout = Duration(seconds: 6);

  /// Converts any WS or HTTP input URL to an HTTP/HTTPS base URL (scheme, host, port).
  static String toHttpBase(String inputUrl) {
    String trimmed = inputUrl.trim();
    if (trimmed.isEmpty) trimmed = '127.0.0.1:9119';

    if (!trimmed.startsWith('ws://') &&
        !trimmed.startsWith('wss://') &&
        !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }

    final parsed = Uri.parse(trimmed);
    final isSecure = parsed.scheme == 'wss' || parsed.scheme == 'https';
    final scheme = isSecure ? 'https' : 'http';
    final host = parsed.host.isNotEmpty ? parsed.host : '127.0.0.1';
    final port = parsed.hasPort ? parsed.port : (isSecure ? 443 : 9119);

    return '$scheme://$host:$port';
  }

  /// Probes the Hermes daemon to detect whether authentication is required
  /// and what providers are available (e.g. username/password basic_auth).
  static Future<AuthRequirementResult> probeAuth(String serverUrl) async {
    final httpBase = toHttpBase(serverUrl);

    try {
      // 1. Probe /api/auth/providers
      final providersUri = Uri.parse('$httpBase/api/auth/providers');
      final res = await http.get(providersUri).timeout(requestTimeout);

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body) as Map<String, dynamic>;
        final providersList = data['providers'] as List<dynamic>? ?? [];

        bool hasPassword = false;
        final names = <String>[];
        String? preferred;

        for (final item in providersList) {
          if (item is Map<String, dynamic>) {
            final name = item['name'] as String? ?? '';
            final supportsPassword = item['supports_password'] as bool? ?? false;
            names.add(name);
            if (supportsPassword) {
              hasPassword = true;
              preferred ??= name;
            }
          }
        }

        return AuthRequirementResult(
          requiresAuth: true,
          supportsPassword: hasPassword,
          providers: names,
          preferredProvider: preferred ?? (names.isNotEmpty ? names.first : 'basic'),
        );
      }

      // 2. Probe root / to check if 302 redirecting to /login
      final rootUri = Uri.parse('$httpBase/');
      final client = http.Client();
      final request = http.Request('GET', rootUri)..followRedirects = false;
      final streamedRes = await client.send(request).timeout(requestTimeout);

      if (streamedRes.statusCode == 302 || streamedRes.statusCode == 307) {
        final location = streamedRes.headers['location'] ?? '';
        if (location.contains('/login')) {
          return const AuthRequirementResult(
            requiresAuth: true,
            supportsPassword: true,
            providers: ['basic'],
            preferredProvider: 'basic',
            message: 'Dashboard requires authentication',
          );
        }
      }
    } catch (e) {
      debugPrint('[HermesAuthService] Probe error for $httpBase: $e');
    }

    return const AuthRequirementResult(
      requiresAuth: false,
      supportsPassword: true,
      providers: ['basic'],
      preferredProvider: 'basic',
    );
  }

  /// Authenticates with username and password against /auth/password-login.
  /// On success, extracts the session access token from the Set-Cookie response.
  static Future<AuthLoginResult> login({
    required String serverUrl,
    required String username,
    required String password,
    String provider = 'basic',
  }) async {
    final httpBase = toHttpBase(serverUrl);
    final loginUri = Uri.parse('$httpBase/auth/password-login');

    try {
      final body = jsonEncode({
        'provider': provider,
        'username': username.trim(),
        'password': password,
        'next': '',
      });

      debugPrint('[HermesAuthService] Attempting login to $loginUri for user: $username');

      final response = await http.post(
        loginUri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        // Extract session access token from Set-Cookie header
        final setCookie = response.headers['set-cookie'] ?? '';
        final token = extractTokenFromSetCookie(setCookie);
        final refreshToken = extractRefreshTokenFromSetCookie(setCookie);

        if (token != null && token.isNotEmpty) {
          debugPrint('[HermesAuthService] Login successful! Token acquired.');

          // Verify with /api/auth/me to get identity
          final me = await getAuthMe(httpBase, token);

          return AuthLoginResult(
            success: true,
            token: token,
            refreshToken: refreshToken,
            userId: me?['user_id'] as String? ?? username,
            displayName: me?['display_name'] as String?,
            email: me?['email'] as String?,
          );
        } else {
          // If token wasn't in Set-Cookie, check if returned in body
          try {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final bodyToken = data['access_token'] as String? ?? data['token'] as String?;
            if (bodyToken != null && bodyToken.isNotEmpty) {
              return AuthLoginResult(
                success: true,
                token: bodyToken,
                userId: username,
              );
            }
          } catch (_) {}

          return AuthLoginResult.failure(
            'Login succeeded but session token was not returned by server.',
          );
        }
      } else if (response.statusCode == 401) {
        return AuthLoginResult.failure('Invalid username or password.');
      } else if (response.statusCode == 429) {
        return AuthLoginResult.failure('Too many login attempts. Please try again shortly.');
      } else if (response.statusCode == 404) {
        return AuthLoginResult.failure('Auth provider "$provider" not supported by server.');
      } else {
        String detail = 'HTTP ${response.statusCode}';
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data.containsKey('detail')) {
            detail = data['detail'].toString();
          }
        } catch (_) {}
        return AuthLoginResult.failure('Login failed: $detail');
      }
    } catch (e) {
      debugPrint('[HermesAuthService] Login exception: $e');
      return AuthLoginResult.failure('Connection error: $e');
    }
  }

  /// Extracts the access token from the Set-Cookie header string.
  /// Matches hermes_session_at, __Host-hermes_session_at, or __Secure-hermes_session_at.
  static String? extractTokenFromSetCookie(String setCookieHeader) {
    if (setCookieHeader.isEmpty) return null;

    final regExp = RegExp(r'(?:__Host-|__Secure-)?hermes_session_at=([^;,\s]+)');
    final match = regExp.firstMatch(setCookieHeader);
    return match?.group(1);
  }

  /// Extracts the refresh token from the Set-Cookie header string.
  static String? extractRefreshTokenFromSetCookie(String setCookieHeader) {
    if (setCookieHeader.isEmpty) return null;

    final regExp = RegExp(r'(?:__Host-|__Secure-)?hermes_session_rt=([^;,\s]+)');
    final match = regExp.firstMatch(setCookieHeader);
    return match?.group(1);
  }

  /// Queries /api/auth/me with Bearer token to inspect active session identity.
  static Future<Map<String, dynamic>?> getAuthMe(String httpBase, String token) async {
    try {
      final uri = Uri.parse('$httpBase/api/auth/me');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Mints a 30s single-use WS upgrade ticket via POST /api/auth/ws-ticket.
  static Future<String?> mintWsTicket(String httpBase, String token) async {
    try {
      final uri = Uri.parse('$httpBase/api/auth/ws-ticket');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['ticket'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
