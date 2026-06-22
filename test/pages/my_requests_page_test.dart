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

    testWidgets(
        'Cenario: Dado usuario pesquisa pedidos, entao total reflete resultados encontrados',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});

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
            return http.Response(
              jsonEncode({
                'content': [
                  _serviceJson(
                    id: 101,
                    creatorId: 1,
                    status: 'CRIADO',
                    title: 'Design Alpha',
                  ),
                  _serviceJson(
                    id: 102,
                    creatorId: 1,
                    status: 'CRIADO',
                    title: 'Backend Beta',
                  ),
                  _serviceJson(
                    id: 103,
                    creatorId: 1,
                    status: 'CONCLUIDO',
                    title: 'Alpha Especial',
                  ),
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

      expect(find.text('3 pedido(s) vinculados ao seu login'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Backend');
      await tester.pumpAndSettle();

      expect(find.text('1 pedido(s) vinculados ao seu login'), findsOneWidget);
      expect(find.text('3 pedido(s) vinculados ao seu login'), findsNothing);
    });

    testWidgets(
        'Cenario: Dado busca ativa, quando carrega mais, entao preenche lote com pedidos correspondentes',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
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
            return http.Response(
              jsonEncode({
                'content': [
                  for (var id = 100; id <= 109; id++)
                    _serviceJson(
                      id: id,
                      creatorId: 1,
                      status: 'CRIADO',
                      title: 'Alvo $id',
                    ),
                  _serviceJson(
                    id: 200,
                    creatorId: 1,
                    status: 'CRIADO',
                    title: 'Alvo 200',
                  ),
                  for (var id = 201; id <= 209; id++)
                    _serviceJson(
                      id: id,
                      creatorId: 1,
                      status: 'CRIADO',
                      title: 'Outro $id',
                    ),
                  for (var id = 210; id <= 218; id++)
                    _serviceJson(
                      id: id,
                      creatorId: 1,
                      status: 'CRIADO',
                      title: 'Alvo $id',
                    ),
                  _serviceJson(
                    id: 219,
                    creatorId: 1,
                    status: 'CRIADO',
                    title: 'Outro 219',
                  ),
                ],
                'page': 0,
                'totalPages': 1,
                'totalElements': 30,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/service/get/all/CRIADO')) {
            serviceRequests++;
            expect(request.url.queryParameters['size'], '10');
            final page = int.parse(request.url.queryParameters['page']!);

            final content = switch (page) {
              0 => [
                  for (var id = 100; id <= 109; id++)
                    _serviceJson(
                      id: id,
                      creatorId: 1,
                      status: 'CRIADO',
                      title: 'Alvo $id',
                    ),
                ],
              1 => [
                  _serviceJson(
                    id: 200,
                    creatorId: 1,
                    status: 'CRIADO',
                    title: 'Alvo 200',
                  ),
                  for (var id = 201; id <= 209; id++)
                    _serviceJson(
                      id: id,
                      creatorId: 1,
                      status: 'CRIADO',
                      title: 'Outro $id',
                    ),
                ],
              2 => [
                  for (var id = 210; id <= 218; id++)
                    _serviceJson(
                      id: id,
                      creatorId: 1,
                      status: 'CRIADO',
                      title: 'Alvo $id',
                    ),
                  _serviceJson(
                    id: 219,
                    creatorId: 1,
                    status: 'CRIADO',
                    title: 'Outro 219',
                  ),
                ],
              _ => <Map<String, dynamic>>[],
            };

            return http.Response(
              jsonEncode({
                'content': content,
                'page': page,
                'totalPages': 3,
                'totalElements': 30,
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

      await tester.enterText(find.byType(TextField), 'Alvo');
      await tester.pumpAndSettle();

      expect(find.text('20 pedido(s) vinculados ao seu login'), findsOneWidget);

      final createdStatus = find
          .byKey(const ValueKey('my-requests-status-created_by_me::CRIADO'));
      await tester.ensureVisible(createdStatus.first);
      await tester.tap(createdStatus.first);
      await tester.pumpAndSettle();

      expect(serviceRequests, 1);
      expect(find.text('Alvo 109'), findsOneWidget);
      expect(find.text('Alvo 200'), findsNothing);

      await tester.ensureVisible(find.text('Carregar mais'));
      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();

      expect(serviceRequests, 3);
      expect(find.text('Alvo 200'), findsOneWidget);
      expect(find.text('Alvo 218'), findsOneWidget);
      expect(find.text('Carregar mais'), findsNothing);
    });
  });
}

Map<String, dynamic> _serviceJson({
  required int id,
  required int creatorId,
  required String status,
  String? title,
}) {
  return {
    'id': id,
    'title': title ?? 'Servico $id',
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
