import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/auth_session_service.dart';

class ApiService {
  static final RegExp _bearerPrefixPattern = RegExp(
    r'^Bearer\s+',
    caseSensitive: false,
  );
  static http.Client? _clientForTesting;

  static http.Client get _client => _clientForTesting ?? http.Client();

  static void setClientForTesting(http.Client? client) {
    _clientForTesting = client;
  }

  static String get baseUrl => AuthSessionService.baseUrl;

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

  static String? _normalizeToken(String? token) {
    final trimmedToken = token?.trim();
    if (trimmedToken == null || trimmedToken.isEmpty) {
      return null;
    }

    return trimmedToken.replaceFirst(_bearerPrefixPattern, '').trim();
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
        final message = decoded['message'] ??
            decoded['error_description'] ??
            decoded['error'];
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
    return _sendRequest(
      endpoint,
      token: token,
      send: (uri, headers) => _client.post(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ),
    );
  }

  static Future<http.Response> get(String endpoint, {String? token}) async {
    return _sendRequest(
      endpoint,
      token: token,
      send: (uri, headers) => _client.get(uri, headers: headers),
    );
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    return _sendRequest(
      endpoint,
      token: token,
      send: (uri, headers) => _client.put(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ),
    );
  }

  static Future<http.Response> delete(String endpoint, {String? token}) async {
    return _sendRequest(
      endpoint,
      token: token,
      send: (uri, headers) => _client.delete(uri, headers: headers),
    );
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

  static Future<http.Response> _sendRequest(
    String endpoint, {
    String? token,
    required Future<http.Response> Function(
      Uri uri,
      Map<String, String> headers,
    ) send,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      var normalizedToken = _normalizeToken(token);
      var response = await send(uri, _buildHeaders(token: normalizedToken));

      if (_shouldAttemptSessionRecovery(response, normalizedToken)) {
        final refreshedToken = await AuthSessionService.refreshSession();
        if (refreshedToken != null && refreshedToken.isNotEmpty) {
          normalizedToken = _normalizeToken(refreshedToken);
          response = await send(
            uri,
            _buildHeaders(token: normalizedToken),
          );
        }

        if (_isUnauthorized(response.statusCode)) {
          await AuthSessionService.handleUnauthorizedResponse();
        }
      }

      return response;
    } catch (e) {
      throw Exception('Erro de conexao: $e');
    }
  }

  static bool _shouldAttemptSessionRecovery(
    http.Response response,
    String? token,
  ) {
    if (token == null || token.isEmpty) {
      return false;
    }

    return _isUnauthorized(response.statusCode);
  }

  static bool _isUnauthorized(int statusCode) {
    return statusCode == 401 || statusCode == 403;
  }
}
