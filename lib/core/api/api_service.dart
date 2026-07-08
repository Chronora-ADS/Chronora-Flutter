import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/app_config.dart';
import '../utils/app_logger.dart';

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
    return _execute('POST', endpoint, () => _client.post(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token),
      body: jsonEncode(data),
    ));
  }

  static Future<http.Response> get(String endpoint, {String? token}) async {
    return _execute('GET', endpoint, () => _client.get(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token),
    ));
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    return _execute('PUT', endpoint, () => _client.put(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token),
      body: jsonEncode(data),
    ));
  }

  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    return _execute('PATCH', endpoint, () => _client.patch(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token),
      body: jsonEncode(data),
    ));
  }

  static Future<http.Response> delete(String endpoint, {String? token}) async {
    return _execute('DELETE', endpoint, () => _client.delete(
      _buildUri(endpoint),
      headers: _buildHeaders(token: token),
    ));
  }

  static Future<http.Response> putWithHeaders(
    String endpoint,
    Map<String, String> headers,
  ) async {
    return _execute('PUT', endpoint, () => _client.put(
      _buildUri(endpoint),
      headers: _buildHeaders(extra: headers),
    ));
  }

  static Future<http.Response> _execute(
    String method,
    String endpoint,
    Future<http.Response> Function() call,
  ) async {
    final sw = Stopwatch()..start();
    try {
      final response = await call();
      sw.stop();
      final ctx = {'method': method, 'endpoint': endpoint,
                   'status': response.statusCode, 'ms': sw.elapsedMilliseconds};
      if (response.statusCode >= 500) {
        AppLogger.error('HTTP $method $endpoint', context: ctx);
      } else if (response.statusCode >= 400) {
        AppLogger.warn('HTTP $method $endpoint', context: ctx);
      } else {
        AppLogger.info('HTTP $method $endpoint', context: ctx);
      }
      return response;
    } catch (e, st) {
      sw.stop();
      AppLogger.error('HTTP $method $endpoint falhou',
          context: {'method': method, 'endpoint': endpoint, 'ms': sw.elapsedMilliseconds},
          error: e, stackTrace: st);
      throw Exception('Erro de conexao: $e');
    }
  }
}
