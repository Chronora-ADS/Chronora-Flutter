import 'dart:convert';

import 'package:chronora/core/constants/app_config.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;

  static Uri _uri(String endpoint) {
    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$baseUrl$normalizedEndpoint');
  }

  static Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      return await http.post(
        _uri(endpoint),
        headers: _headers(token: token),
        body: jsonEncode(data),
      );
    } catch (e) {
      throw Exception('Erro de conexao: $e');
    }
  }

  static Future<http.Response> get(
    String endpoint, {
    String? token,
  }) async {
    try {
      return await http.get(
        _uri(endpoint),
        headers: _headers(token: token),
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
      return await http.put(
        _uri(endpoint),
        headers: _headers(token: token),
        body: jsonEncode(data),
      );
    } catch (e) {
      throw Exception('Erro de conexao: $e');
    }
  }

  static Future<http.Response> delete(
    String endpoint, {
    String? token,
  }) async {
    try {
      return await http.delete(
        _uri(endpoint),
        headers: _headers(token: token),
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
      return await http.put(
        _uri(endpoint),
        headers: {
          'Content-Type': 'application/json',
          ...headers,
        },
      );
    } catch (e) {
      throw Exception('Erro de conexao: $e');
    }
  }

  
  static Future<http.Response> putString(
    String endpoint,
    String data, {
    String? token,
  }) async {
    try {
      return await http.put(
        _uri(endpoint),
        headers: {
          'Content-Type': 'text/plain',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: data,
      );
    } catch (e) {
      throw Exception('Erro de conexao: $e');
    }
  }
}
