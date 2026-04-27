import 'dart:convert';
import 'package:http/http.dart' as http; //

class ApiService {
  // static const String baseUrl = 'https://chronora-java.onrender.com';
  static const String baseUrl = 'http://localhost:8085';
  static const Duration _defaultTimeout = Duration(seconds: 45);

  static Future<http.Response> post(String endpoint, Map<String, dynamic> data,
      {String? token, Duration? timeout}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(timeout ?? _defaultTimeout);
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<http.Response> get(
    String endpoint, {
    String? token,
    Duration? timeout,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ).timeout(timeout ?? _defaultTimeout);
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> data,
    {String? token, Duration? timeout}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(timeout ?? _defaultTimeout);
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<http.Response> putWithHeaders(
    String endpoint,
    Map<String, String> headers, {
    Duration? timeout,
  }) async {
    try {
      final finalHeaders = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        ...headers, // Mescla os headers fornecidos
      };

      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: finalHeaders,
      ).timeout(timeout ?? _defaultTimeout);
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
