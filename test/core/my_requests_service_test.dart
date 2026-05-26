import 'dart:convert';

import 'package:chronora/core/api/api_service.dart';
import 'package:chronora/core/services/my_requests_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    ApiService.setClientForTesting(null);
  });

  group('Funcionalidade: carregamento de meus pedidos', () {
    test('busca todas as paginas retornadas pela API', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': _buildJwt({
          'id': 1,
          'name': 'Ana',
          'email': 'ana@example.com',
        }),
      });

      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response(
              jsonEncode({
                'id': 1,
                'name': 'Ana',
                'email': 'ana@example.com',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/service/get/all')) {
            final page = int.parse(request.url.queryParameters['page'] ?? '0');
            final size = int.parse(request.url.queryParameters['size'] ?? '0');

            expect(size, 2);

            if (page == 0) {
              return http.Response(
                jsonEncode({
                  'content': [
                    _serviceJson(id: 101, creatorId: 1, status: 'CRIADO'),
                    _serviceJson(
                        id: 102, creatorId: 2, acceptedId: 1, status: 'ACEITO'),
                  ],
                  'page': 0,
                  'totalPages': 2,
                  'totalElements': 3,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }

            if (page == 1) {
              return http.Response(
                jsonEncode({
                  'content': [
                    _serviceJson(id: 103, creatorId: 1, status: 'CONCLUIDO'),
                  ],
                  'page': 1,
                  'totalPages': 2,
                  'totalElements': 3,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }
          }

          return http.Response('not found', 404);
        }),
      );

      final result = await MyRequestsService().loadMyRequests(pageSize: 2);

      expect(result.currentUser.id, 1);
      expect(result.services.map((item) => item.service.id).toSet(), {
        101,
        102,
        103,
      });
      expect(result.stats.pagesFetched, 2);
      expect(result.stats.rawItemsFetched, 3);
      expect(result.stats.uniqueServicesFetched, 3);
      expect(result.stats.totalElements, 3);
    });

    test('usa o token como fallback quando /user/get falha', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': _buildJwt({
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier':
              '7',
          'email': 'fallback@example.com',
          'name': 'Usuario Fallback',
        }),
      });

      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response('erro', 500);
          }

          if (request.url.path.endsWith('/service/get/all')) {
            return http.Response(
              jsonEncode({
                'content': <Map<String, dynamic>>[],
                'page': 0,
                'totalPages': 1,
                'totalElements': 0,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('not found', 404);
        }),
      );

      final result = await MyRequestsService().loadMyRequests(pageSize: 2);

      expect(result.currentUser.id, 7);
      expect(result.currentUser.email, 'fallback@example.com');
      expect(result.currentUser.name, 'Usuario Fallback');
      expect(result.services, isEmpty);
      expect(result.stats.pagesFetched, 1);
    });
  });
}

String _buildJwt(Map<String, dynamic> payload) {
  final header = base64UrlEncode(utf8.encode(jsonEncode({'alg': 'none'})));
  final body = base64UrlEncode(utf8.encode(jsonEncode(payload)));
  return '$header.$body.signature';
}

Map<String, dynamic> _serviceJson({
  required int id,
  required int creatorId,
  int? acceptedId,
  required String status,
}) {
  return {
    'id': id,
    'title': 'Servico $id',
    'description': 'Descricao do servico $id',
    'serviceImageUrl': '/uploads/$id.png',
    'timeChronos': 2,
    'status': status,
    'userCreator': {
      'id': creatorId,
      'name': 'Criador $creatorId',
      'email': 'criador$creatorId@example.com',
    },
    if (acceptedId != null)
      'userAccepted': {
        'id': acceptedId,
        'name': 'Aceito $acceptedId',
        'email': 'aceito$acceptedId@example.com',
      },
    'categories': [
      {'name': 'Categoria'}
    ],
    'deadline': '2026-06-01',
    'modality': 'REMOTO',
  };
}
