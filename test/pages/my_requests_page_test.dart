import 'dart:convert';

import 'package:chronora/core/api/api_service.dart';
import 'package:chronora/pages/requests/my_requests.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    ApiService.setClientForTesting(null);
  });

  group('Funcionalidade: meus pedidos sob demanda', () {
    testWidgets(
        'Cenario: Dado tela aberta, quando seleciona status, entao mostra total e mantem ordenacao',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
      var allRequests = 0;
      var serviceRequests = 0;

      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response(
              jsonEncode({
                'id': 1,
                'name': 'Ana',
                'email': 'ana@example.com',
                'timeChronos': 8,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/service/get/all')) {
            allRequests++;
            expect(request.url.queryParameters['page'], '0');
            expect(request.url.queryParameters['size'], '50');

            return http.Response(
              jsonEncode({
                'content': [
                  _serviceJson(id: 101, creatorId: 1, status: 'CRIADO'),
                  _serviceJson(id: 102, creatorId: 1, status: 'CRIADO'),
                  _serviceJson(id: 103, creatorId: 1, status: 'CRIADO'),
                ],
                'page': 0,
                'totalPages': 1,
                'totalElements': 3,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/service/get/all/CRIADO')) {
            serviceRequests++;
            expect(request.url.queryParameters['page'], '0');
            expect(request.url.queryParameters['size'], '10');

            return http.Response(
              jsonEncode({
                'content': [
                  _serviceJson(id: 101, creatorId: 1, status: 'CRIADO'),
                  _serviceJson(id: 103, creatorId: 1, status: 'CRIADO'),
                  _serviceJson(id: 102, creatorId: 1, status: 'CRIADO'),
                ],
                'page': 0,
                'totalPages': 1,
                'totalElements': 3,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('not found', 404);
        }),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              padding: EdgeInsets.only(top: 24),
              size: Size(390, 844),
            ),
            child: MeusPedidosPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(allRequests, 1);
      expect(serviceRequests, 0);
      expect(find.text('3 pedido(s) vinculados ao seu login'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('my-requests-status-created_by_me::CRIADO'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('my-requests-status-accepted_from_others::CRIADO'),
        ),
        findsNothing,
      );
      expect(find.text('Servico 101'), findsNothing);

      final createdStatus = find
          .byKey(const ValueKey('my-requests-status-created_by_me::CRIADO'));
      await tester.ensureVisible(createdStatus.first);
      await tester.tap(createdStatus.first);
      await tester.pumpAndSettle();

      expect(serviceRequests, 1);
      expect(find.text('Servico 101'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Servico 103')).dy,
        lessThan(tester.getTopLeft(find.text('Servico 102')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Servico 102')).dy,
        lessThan(tester.getTopLeft(find.text('Servico 101')).dy),
      );
    });
  });
}

Map<String, dynamic> _serviceJson({
  required int id,
  required int creatorId,
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
      'name': 'Ana',
      'email': 'ana@example.com',
    },
    'categories': [
      {'name': 'Categoria'}
    ],
    'deadline': '2026-06-01',
    'modality': 'REMOTO',
  };
}
