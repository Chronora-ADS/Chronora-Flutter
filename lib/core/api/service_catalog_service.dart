import 'dart:convert';

import '../models/main_page_requests_model.dart';
import '../services/auth_session_service.dart';
import 'api_service.dart';

class ServiceCatalogService {
  Future<ServiceListResult> fetchServices({
    int? page,
    int? size,
    String? status,
    String? query,
    List<String> categories = const [],
    String? modality,
    DateTime? deadline,
    int? minTimeChronos,
    int? maxTimeChronos,
    String? sort,
  }) async {
    final String? token = await _getToken();

    if (token == null) {
      throw const ServiceCatalogException(
        'Você precisa estar logado para visualizar os serviços.',
      );
    }

    final queryParameters = <String, List<String>>{};
    void addQueryValue(String key, Object? value) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) return;
      queryParameters.putIfAbsent(key, () => <String>[]).add(text);
    }

    addQueryValue('page', page);
    addQueryValue('size', size);
    addQueryValue('query', query);
    for (final category in categories) {
      addQueryValue('categories', category);
    }
    addQueryValue('modality', modality);
    if (deadline != null) {
      addQueryValue('deadline', _formatDate(deadline));
    }
    addQueryValue('minTimeChronos', minTimeChronos);
    addQueryValue('maxTimeChronos', maxTimeChronos);
    addQueryValue('sort', sort);

    final path = status == null || status.trim().isEmpty
        ? '/service/get/all'
        : '/service/get/all/${Uri.encodeComponent(status.trim())}';
    final queryString = Uri(queryParameters: queryParameters).query;
    final endpoint = queryString.isEmpty ? path : '$path?$queryString';

    final response = await ApiService.get(endpoint, token: token);

    if (response.statusCode != 200) {
      throw ServiceCatalogException(
        'Erro ${response.statusCode} ao carregar os serviços.',
        statusCode: response.statusCode,
      );
    }

    return _parseServicesResponse(response.body);
  }

  Future<String?> _getToken() async {
    return AuthSessionService.getValidAccessToken();
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

  String _formatDate(DateTime date) {
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
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
