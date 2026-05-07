import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_config.dart';
import '../constants/app_routes.dart';

class AuthSessionService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static bool _isRedirectingToLogin = false;
  static const String _defaultLocalBaseUrl = 'http://localhost:8085';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8085';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _accessTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'auth_expires_at';
  static const Duration _refreshLeeway = Duration(minutes: 1);
  static final RegExp _bearerPrefixPattern = RegExp(
    r'^Bearer\s+',
    caseSensitive: false,
  );

  static Future<String?>? _refreshInFlight;
  static Future<void>? _unauthorizedHandlingInFlight;

  static String get baseUrl {
    final configuredBaseUrl = _configuredBaseUrl.trim();
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    if (kIsWeb || kReleaseMode) {
      return AppConfig.apiBaseUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorBaseUrl;
    }

    return _defaultLocalBaseUrl;
  }

  static Future<void> saveSessionFromResponse(
    Map<String, dynamic> responseData, {
    bool preserveExistingRefreshToken = false,
  }) async {
    final accessToken = _readString(
      responseData,
      const ['access_token', 'accessToken', 'token'],
    );

    final normalizedAccessToken = _normalizeToken(accessToken);
    if (normalizedAccessToken == null || normalizedAccessToken.isEmpty) {
      throw const FormatException(
          'Token de acesso nao encontrado na resposta.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, normalizedAccessToken);

    final refreshToken = _readString(
      responseData,
      const ['refresh_token', 'refreshToken'],
    );
    final normalizedRefreshToken = _normalizeToken(refreshToken);
    if (normalizedRefreshToken != null && normalizedRefreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, normalizedRefreshToken);
    } else if (!preserveExistingRefreshToken) {
      await prefs.remove(_refreshTokenKey);
    }

    final expiresAt = _extractExpiresAt(responseData) ??
        _extractJwtExpiration(normalizedAccessToken);
    if (expiresAt != null) {
      await prefs.setInt(_expiresAtKey, expiresAt.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_expiresAtKey);
    }
  }

  static Future<String?> getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final persistedAccessToken = prefs.getString(_accessTokenKey);
    final accessToken = _normalizeToken(persistedAccessToken);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    if (persistedAccessToken != accessToken) {
      await prefs.setString(_accessTokenKey, accessToken);
    }

    final expiresAt = await _resolveTokenExpiration(
      prefs: prefs,
      accessToken: accessToken,
    );
    if (expiresAt == null) {
      return accessToken;
    }

    final now = DateTime.now();

    if (now.isBefore(expiresAt.subtract(_refreshLeeway))) {
      return accessToken;
    }

    final refreshedToken = await refreshSession();
    if (refreshedToken != null) {
      return refreshedToken;
    }

    if (now.isBefore(expiresAt)) {
      return accessToken;
    }

    await clearSession();
    return null;
  }

  static Future<String?> refreshSession() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    _refreshInFlight = _refreshSessionImpl();
    try {
      return await _refreshInFlight!;
    } finally {
      _refreshInFlight = null;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiresAtKey);
  }

  static Future<void> handleUnauthorizedResponse() async {
    if (_unauthorizedHandlingInFlight != null) {
      return _unauthorizedHandlingInFlight!;
    }

    _unauthorizedHandlingInFlight = _handleUnauthorizedResponseImpl();
    try {
      await _unauthorizedHandlingInFlight!;
    } finally {
      _unauthorizedHandlingInFlight = null;
    }
  }

  static Future<String?> _refreshSessionImpl() async {
    final prefs = await SharedPreferences.getInstance();
    final persistedRefreshToken = prefs.getString(_refreshTokenKey);
    final refreshToken = _normalizeToken(persistedRefreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    if (persistedRefreshToken != refreshToken) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }

    final endpoint = Uri.parse(baseUrl).resolve(
      'auth/refresh',
    );
    final payloads = <Map<String, dynamic>>[
      {'refresh_token': refreshToken},
      {'refreshToken': refreshToken},
    ];

    for (final payload in payloads) {
      final response = await http.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.trim();
        if (body.isEmpty) {
          await clearSession();
          return null;
        }

        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) {
          await clearSession();
          return null;
        }

        await saveSessionFromResponse(
          decoded,
          preserveExistingRefreshToken: true,
        );
        return _normalizeToken(
          _readString(
            decoded,
            const ['access_token', 'accessToken', 'token'],
          ),
        );
      }

      if (response.statusCode != 400 &&
          response.statusCode != 401 &&
          response.statusCode != 404 &&
          response.statusCode != 415) {
        break;
      }
    }

    await clearSession();
    return null;
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static String? _normalizeToken(String? value) {
    final trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) {
      return null;
    }

    final unquotedValue = trimmedValue.replaceAll('"', '');
    return unquotedValue.replaceFirst(_bearerPrefixPattern, '').trim();
  }

  static Future<DateTime?> _resolveTokenExpiration({
    required SharedPreferences prefs,
    required String accessToken,
  }) async {
    final expiresAtMillis = prefs.getInt(_expiresAtKey);
    if (expiresAtMillis != null) {
      return DateTime.fromMillisecondsSinceEpoch(expiresAtMillis);
    }

    final jwtExpiration = _extractJwtExpiration(accessToken);
    if (jwtExpiration != null) {
      await prefs.setInt(_expiresAtKey, jwtExpiration.millisecondsSinceEpoch);
    }
    return jwtExpiration;
  }

  static DateTime? _extractExpiresAt(Map<String, dynamic> data) {
    final expiresIn = data['expires_in'] ?? data['expiresIn'];
    if (expiresIn is int) {
      return DateTime.now().add(Duration(seconds: expiresIn));
    }
    if (expiresIn is num) {
      return DateTime.now().add(Duration(seconds: expiresIn.toInt()));
    }
    if (expiresIn is String) {
      final seconds = int.tryParse(expiresIn);
      if (seconds != null) {
        return DateTime.now().add(Duration(seconds: seconds));
      }
    }

    final expiresAt = data['expires_at'] ?? data['expiresAt'];
    if (expiresAt is int) {
      return DateTime.fromMillisecondsSinceEpoch(expiresAt);
    }
    if (expiresAt is num) {
      return DateTime.fromMillisecondsSinceEpoch(expiresAt.toInt());
    }
    if (expiresAt is String) {
      final asInt = int.tryParse(expiresAt);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }
      return DateTime.tryParse(expiresAt);
    }

    return null;
  }

  static DateTime? _extractJwtExpiration(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return null;
      }

      final normalizedPayload = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalizedPayload));
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final exp = decoded['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      }
      if (exp is String) {
        final parsedExp = int.tryParse(exp);
        if (parsedExp != null) {
          return DateTime.fromMillisecondsSinceEpoch(parsedExp * 1000);
        }
      }
    } catch (_) {
      // Ignore malformed JWTs and fall back to explicit expiration metadata.
    }

    return null;
  }

  static Future<void> _handleUnauthorizedResponseImpl() async {
    await clearSession();
    _redirectToLogin();
  }

  static void _redirectToLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator == null || _isRedirectingToLogin) {
      return;
    }

    _isRedirectingToLogin = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentNavigator = navigatorKey.currentState;
      if (currentNavigator == null) {
        _isRedirectingToLogin = false;
        return;
      }

      currentNavigator.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
      _isRedirectingToLogin = false;
    });
  }
}
