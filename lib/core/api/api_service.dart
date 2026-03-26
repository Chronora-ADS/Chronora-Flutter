import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _defaultBaseUrl = 'http://localhost:8085';
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

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

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data,
      {String? token}) async {
    try {
      final headers = _buildHeaders(token: token);

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<http.Response> get(String endpoint, {String? token}) async {
    try {
      final headers = _buildHeaders(token: token);

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data,
      {String? token}) async {
    try {
      final headers = _buildHeaders(token: token);

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<http.Response> putWithHeaders(
    String endpoint,
    Map<String, String> headers,
  ) async {
    try {
      final finalHeaders = _buildHeaders(extra: headers);

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: finalHeaders,
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
