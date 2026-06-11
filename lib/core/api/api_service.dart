import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/app_config.dart';

class ApiService {
  static const String _defaultLocalBaseUrl = 'http://localhost:8085';
  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8085';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static http.Client? _clientForTesting;

  static http.Client get _client => _clientForTesting ?? http.Client();

  static void setClientForTesting(http.Client? client) {
    _clientForTesting = client;
  }

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

  static Map<String, String> _buildHeaders({
    String? token,
    Map<String, String>? extra,
  }) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (extra != null) ...extra,
    };
  }

  static Uri _buildUri(String endpoint) {
    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return Uri.parse(baseUrl).resolve(normalizedEndpoint);
  }

  static String extractErrorMessage(
    String body, {
    String fallback = 'Erro ao processar a requisicao.',
  }) {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return fallback;
    }

    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        final message =
            decoded['message'] ?? decoded['error_description'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // If the backend did not return JSON, use the raw response body.
    }

    return trimmedBody;
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      final headers = _buildHeaders(token: token);

      return await _client.post(
        _buildUri(endpoint),
        headers: headers,
        body: jsonEncode(data),
      );
    } catch (e) {
      throw Exception('Erro de conexao: $e');
    }
  }

  static Future<http.Response> get(String endpoint, {String? token}) async {
    try {
      final headers = _buildHeaders(token: token);

      return await _client.get(
        _buildUri(endpoint),
        headers: headers,
      );
    } catch (e) {
      throw Exception('Erro de conexao: $e');
    }
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      final headers = _buildHeaders(token: token);

      return await _client.put(
        _buildUri(endpoint),
        headers: headers,
        body: jsonEncode(data),
      );
    } catch (e) {
      throw Exception('Erro de conexao: $e');
    }
  }

  static Future<http.Response> delete(String endpoint, {String? token}) async {
    try {
      final headers = _buildHeaders(token: token);

      return await _client.delete(
        _buildUri(endpoint),
        headers: headers,
      );
    } catch (e) {
      throw Exception('Erro de conexao: $e');
    }
  }

  static Future<http.Response> putWithHeaders(
    String endpoint,
    Map<String, String> headers,
  ) async {
    try {
      final finalHeaders = _buildHeaders(extra: headers);

      return await _client.put(
        _buildUri(endpoint),
        headers: finalHeaders,
      );
    } catch (e) {
      throw Exception('Erro de conexao: $e');
    }
  }
}
