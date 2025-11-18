import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // static const String baseUrl = 'https://chronora-java.onrender.com';
  static const String baseUrl = 'http://localhost:8085';

  static Future<http.Response> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: jsonEncode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<http.Response> get(String endpoint, {String? token}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<http.Response> delete(
    String endpoint, {
    String? token,
  }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
      return response;
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}
