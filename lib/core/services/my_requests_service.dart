import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/api_service.dart';
import '../models/main_page_requests_model.dart';
import 'auth_session_service.dart';

class MyRequestsUserIdentity {
  final int? id;
  final String name;
  final String email;

  const MyRequestsUserIdentity({
    required this.id,
    required this.name,
    required this.email,
  });

  bool get isEmpty => id == null && name.isEmpty && email.isEmpty;
}

class ServiceEnvelope {
  final Service service;
  final Map<String, dynamic> raw;

  const ServiceEnvelope({
    required this.service,
    required this.raw,
  });
}

class MyRequestsLoadStats {
  final int pagesFetched;
  final int rawItemsFetched;
  final int uniqueServicesFetched;
  final int? totalElements;

  const MyRequestsLoadStats({
    required this.pagesFetched,
    required this.rawItemsFetched,
    required this.uniqueServicesFetched,
    required this.totalElements,
  });
}

class MyRequestsLoadResult {
  final MyRequestsUserIdentity currentUser;
  final List<ServiceEnvelope> services;
  final MyRequestsLoadStats stats;

  const MyRequestsLoadResult({
    required this.currentUser,
    required this.services,
    required this.stats,
  });
}

class MyRequestsStatusPage {
  final List<ServiceEnvelope> services;
  final int page;
  final int? totalPages;
  final int? totalElements;

  const MyRequestsStatusPage({
    required this.services,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });

  bool get hasMore {
    if (totalPages == null) {
      return services.isNotEmpty;
    }
    return page + 1 < totalPages!;
  }
}

class MyRequestsException implements Exception {
  final String message;

  const MyRequestsException(this.message);

  @override
  String toString() => message;
}

class MyRequestsService {
  static const int defaultPageSize = 50;

  Future<MyRequestsLoadResult> loadMyRequests({
    int pageSize = defaultPageSize,
  }) async {
    final currentUser = await loadCurrentUser();
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) {
      throw const MyRequestsException(
        'Voce precisa estar logado para visualizar seus pedidos.',
      );
    }

    final pagedResult = await _fetchAllServices(
      token: token,
      pageSize: pageSize,
    );

    return MyRequestsLoadResult(
      currentUser: currentUser,
      services: pagedResult.services,
      stats: MyRequestsLoadStats(
        pagesFetched: pagedResult.pagesFetched,
        rawItemsFetched: pagedResult.rawItemsFetched,
        uniqueServicesFetched: pagedResult.services.length,
        totalElements: pagedResult.totalElements,
      ),
    );
  }

  Future<MyRequestsUserIdentity> loadCurrentUser() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) {
      throw const MyRequestsException(
        'Voce precisa estar logado para visualizar seus pedidos.',
      );
    }

    return _fetchCurrentUser(token);
  }

  Future<MyRequestsStatusPage> loadStatusPage({
    required String status,
    required int page,
    required int pageSize,
  }) async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) {
      throw const MyRequestsException(
        'Voce precisa estar logado para visualizar seus pedidos.',
      );
    }

    final normalizedStatus = Uri.encodeComponent(status.trim().toUpperCase());
    final response = await ApiService.get(
      '/service/get/all/$normalizedStatus?page=$page&size=$pageSize',
      token: token,
    );

    if (response.statusCode != 200) {
      throw MyRequestsException(
        'Erro ${response.statusCode} ao carregar seus pedidos.',
      );
    }

    final parsedPage = _parseServicesPage(response.body);
    return MyRequestsStatusPage(
      services: parsedPage.items,
      page: parsedPage.page ?? page,
      totalPages: parsedPage.totalPages,
      totalElements: parsedPage.totalElements,
    );
  }

  @visibleForTesting
  MyRequestsUserIdentity extractUserFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return const MyRequestsUserIdentity(id: null, name: '', email: '');
      }

      final normalizedPayload = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalizedPayload));
      final data = json.decode(payload);

      if (data is! Map<String, dynamic>) {
        return const MyRequestsUserIdentity(id: null, name: '', email: '');
      }

      return MyRequestsUserIdentity(
        id: _extractIdFromClaims(data),
        name: _extractStringFromMap(data, const [
          'name',
          'unique_name',
          'preferred_username',
          'user_name',
          'username',
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name',
        ]),
        email: _extractStringFromMap(data, const [
          'email',
          'sub',
          'upn',
          'preferred_username',
          'username',
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
        ]),
      );
    } catch (_) {
      return const MyRequestsUserIdentity(id: null, name: '', email: '');
    }
  }

  Future<MyRequestsUserIdentity> _fetchCurrentUser(String token) async {
    final fallbackUser = extractUserFromToken(token);

    try {
      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode != 200) {
        return fallbackUser;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return fallbackUser;
      }

      return MyRequestsUserIdentity(
        id: _toInt(decoded['id'] ?? decoded['userId'] ?? decoded['user_id']) ??
            fallbackUser.id,
        name: _firstNonEmpty([
              decoded['name'],
              decoded['userName'],
              decoded['unique_name'],
            ]) ??
            fallbackUser.name,
        email: _firstNonEmpty([
              decoded['email'],
              decoded['username'],
              decoded['preferred_username'],
            ]) ??
            fallbackUser.email,
      );
    } catch (_) {
      return fallbackUser;
    }
  }

  Future<_PagedServicesResult> _fetchAllServices({
    required String token,
    required int pageSize,
  }) async {
    final merged = <int, ServiceEnvelope>{};
    var page = 0;
    var pagesFetched = 0;
    var rawItemsFetched = 0;
    int? totalElements;

    while (true) {
      final response = await ApiService.get(
        '/service/get/all?page=$page&size=$pageSize',
        token: token,
      );

      if (response.statusCode != 200) {
        throw MyRequestsException(
          'Erro ${response.statusCode} ao carregar seus pedidos.',
        );
      }

      final parsedPage = _parseServicesPage(response.body);
      pagesFetched++;
      rawItemsFetched += parsedPage.items.length;
      totalElements ??= parsedPage.totalElements;

      final uniqueCountBefore = merged.length;
      for (final envelope in parsedPage.items) {
        merged[envelope.service.id] = envelope;
      }

      final currentPage = parsedPage.page ?? page;
      final nextPage = currentPage + 1;
      final addedOnThisPage = merged.length - uniqueCountBefore;
      final hasMore = parsedPage.totalPages != null
          ? nextPage < parsedPage.totalPages!
          : parsedPage.items.length >= pageSize && addedOnThisPage > 0;

      if (!hasMore || parsedPage.items.isEmpty) {
        break;
      }

      page = nextPage;
    }

    return _PagedServicesResult(
      services: merged.values.toList(),
      pagesFetched: pagesFetched,
      rawItemsFetched: rawItemsFetched,
      totalElements: totalElements,
    );
  }

  _ParsedServicesPage _parseServicesPage(String responseBody) {
    final responseData = json.decode(responseBody);
    List<dynamic> items = const [];
    int? page;
    int? totalPages;
    int? totalElements;

    if (responseData is Map<String, dynamic>) {
      if (responseData['services'] is List) {
        items = responseData['services'] as List<dynamic>;
      } else if (responseData['data'] is List) {
        items = responseData['data'] as List<dynamic>;
      } else if (responseData['content'] is List) {
        items = responseData['content'] as List<dynamic>;
      }

      page = _toInt(responseData['page']);
      totalPages = _toInt(responseData['totalPages']);
      totalElements = _toInt(responseData['totalElements']);
    } else if (responseData is List<dynamic>) {
      items = responseData;
    }

    return _ParsedServicesPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => ServiceEnvelope(
              service: Service.fromJson(item),
              raw: item,
            ),
          )
          .toList(),
      page: page,
      totalPages: totalPages,
      totalElements: totalElements,
    );
  }

  int? _extractIdFromClaims(Map<String, dynamic> data) {
    for (final key in const [
      'id',
      'userId',
      'user_id',
      'nameid',
      'nameidentifier',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
    ]) {
      final value = _toInt(data[key]);
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String _extractStringFromMap(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final normalized = value?.toString().trim() ?? '';
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class _ParsedServicesPage {
  final List<ServiceEnvelope> items;
  final int? page;
  final int? totalPages;
  final int? totalElements;

  const _ParsedServicesPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalElements,
  });
}

class _PagedServicesResult {
  final List<ServiceEnvelope> services;
  final int pagesFetched;
  final int rawItemsFetched;
  final int? totalElements;

  const _PagedServicesResult({
    required this.services,
    required this.pagesFetched,
    required this.rawItemsFetched,
    required this.totalElements,
  });
}
