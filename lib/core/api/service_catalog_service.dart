import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/main_page_requests_model.dart';
import 'api_service.dart';

class ServiceCatalogService {
  Future<ServiceListResult> fetchServices() async {
    final String? token = await _getToken();

    if (token == null) {
      throw const ServiceCatalogException(
        'Voce precisa estar logado para visualizar os servicos.',
      );
    }

    final response = await ApiService.get('/service/get/all', token: token);

    if (response.statusCode != 200) {
      throw ServiceCatalogException(
        'Erro ${response.statusCode} ao carregar os servicos.',
        statusCode: response.statusCode,
      );
    }

    return _parseServicesResponse(response.body);
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  ServiceListResult _parseServicesResponse(String body) {
    final dynamic decoded = json.decode(body);

    if (decoded is List) {
      return ServiceListResult(services: _mapToServices(decoded));
    }

    if (decoded is Map<String, dynamic>) {
      final list = _extractListFromMap(decoded);
      return ServiceListResult(
        services: _mapToServices(list),
        page: _toInt(decoded['page']),
        size: _toInt(decoded['size']),
        totalElements: _toInt(decoded['totalElements']),
        totalPages: _toInt(decoded['totalPages']),
        message: decoded['message']?.toString(),
      );
    }

    return ServiceListResult(services: const []);
  }

  List<Service> _mapToServices(List<dynamic> items) {
    return items
        .whereType<Map<String, dynamic>>()
        .map(Service.fromJson)
        .toList();
  }

  List<dynamic> _extractListFromMap(Map<String, dynamic> map) {
    const keys = ['services', 'data', 'content'];
    for (final key in keys) {
      final value = map[key];
      if (value is List) {
        return value;
      }
    }
    return const [];
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class ServiceListResult {
  final List<Service> services;
  final int? page;
  final int? size;
  final int? totalElements;
  final int? totalPages;
  final String? message;

  ServiceListResult({
    required this.services,
    this.page,
    this.size,
    this.totalElements,
    this.totalPages,
    this.message,
  });
}

class ServiceCatalogException implements Exception {
  final String message;
  final int? statusCode;

  const ServiceCatalogException(this.message, {this.statusCode});

  @override
  String toString() => 'ServiceCatalogException(message: $message)';
}
