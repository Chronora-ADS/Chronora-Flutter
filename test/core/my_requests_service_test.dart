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
    test('loadCounts retorna contagens por grupo a partir do endpoint dedicado',
        () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': _buildJwt({
          'id': 1,
          'name': 'Ana',
          'email': 'ana@example.com',
        }),
      });

      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/service/my-services/counts')) {
            return http.Response(
              jsonEncode({
                'createdByMe': {
                  'CRIADO': 2,
                  'ACEITO': 0,
                  'EM_ANDAMENTO': 1,
                  'CONCLUIDO': 3,
                  'CANCELADO': 0,
                  'AGUARDANDO_CONFIRMACAO': 0,
                },
                'acceptedFromOthers': {
                  'CRIADO': 0,
                  'ACEITO': 1,
                  'EM_ANDAMENTO': 0,
                  'CONCLUIDO': 2,
                  'CANCELADO': 0,
                  'AGUARDANDO_CONFIRMACAO': 0,
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('not found', 404);
        }),
      );

      final counts = await MyRequestsService().loadCounts();

      expect(counts.createdByMe['CRIADO'], 2);
      expect(counts.createdByMe['EM_ANDAMENTO'], 1);
      expect(counts.createdByMe['CONCLUIDO'], 3);
      expect(counts.acceptedFromOthers['ACEITO'], 1);
      expect(counts.acceptedFromOthers['CONCLUIDO'], 2);
    });

    test('loadCurrentUser usa o token como fallback quando /user/get falha',
        () async {
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

          return http.Response('not found', 404);
        }),
      );

      final user = await MyRequestsService().loadCurrentUser();

      expect(user.id, 7);
      expect(user.email, 'fallback@example.com');
      expect(user.name, 'Usuario Fallback');
    });

    test('loadStatusPage busca pedidos filtrados por role e status', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': _buildJwt({
          'id': 1,
          'name': 'Ana',
          'email': 'ana@example.com',
        }),
      });

      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/service/my-services')) {
            expect(request.url.queryParameters['role'], 'created');
            expect(request.url.queryParameters['status'], 'CRIADO');
            expect(request.url.queryParameters['page'], '2');
            expect(request.url.queryParameters['size'], '10');

            return http.Response(
              jsonEncode({
                'content': [
                  _serviceJson(id: 201, creatorId: 1, status: 'CRIADO'),
                ],
                'page': 2,
                'totalPages': 4,
                'totalElements': 31,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('not found', 404);
        }),
      );

      final result = await MyRequestsService().loadStatusPage(
        role: 'created',
        status: 'CRIADO',
        page: 2,
        pageSize: 10,
      );

      expect(result.services.single.service.id, 201);
      expect(result.page, 2);
      expect(result.totalPages, 4);
      expect(result.totalElements, 31);
      expect(result.hasMore, isTrue);
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
