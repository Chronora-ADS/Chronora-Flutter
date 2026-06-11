import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_service.dart';

class AuthSessionService {
  static const String _accessTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiresAtKey = 'auth_expires_at';
  static const Duration _refreshLeeway = Duration(minutes: 1);

  static Future<String?>? _refreshInFlight;

  static Future<void> saveSessionFromResponse(
    Map<String, dynamic> responseData, {
    bool preserveExistingRefreshToken = false,
  }) async {
    final accessToken = _readString(
      responseData,
      const ['access_token', 'accessToken', 'token'],
    );

    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException('Token de acesso nao encontrado na resposta.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);

    final refreshToken = _readString(
      responseData,
      const ['refresh_token', 'refreshToken'],
    );
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else if (!preserveExistingRefreshToken) {
      await prefs.remove(_refreshTokenKey);
    }

    final expiresAt = _extractExpiresAt(responseData);
    if (expiresAt != null) {
      await prefs.setInt(_expiresAtKey, expiresAt.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_expiresAtKey);
    }
  }

  static Future<String?> getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(_accessTokenKey);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final expiresAtMillis = prefs.getInt(_expiresAtKey);
    if (expiresAtMillis == null) {
      return accessToken;
    }

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMillis);
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

  static Future<String?> _refreshSessionImpl() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final endpoint = Uri.parse(ApiService.baseUrl).resolve('auth/refresh');
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
        return _readString(
          decoded,
          const ['access_token', 'accessToken', 'token'],
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
}
