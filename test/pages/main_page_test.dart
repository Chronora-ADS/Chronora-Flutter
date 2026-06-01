import 'dart:convert';

import 'package:chronora/core/api/api_service.dart';
import 'package:chronora/pages/main_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    ApiService.setClientForTesting(null);
  });

  group('Funcionalidade: pagina inicial', () {
    testWidgets(
        'Cenario: Dado pedidos paginados, quando carrega mais, entao novos pedidos aparecem abaixo dos existentes',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});

      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response(
              jsonEncode({
                'id': 1,
                'name': 'Ana',
                'timeChronos': 8,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (_isServiceListRequest(request)) {
            final page = int.parse(request.url.queryParameters['page'] ?? '0');

            if (page == 0) {
              return http.Response(
                jsonEncode({
                  'content': _servicePage(startId: 1, count: 10),
                  'page': 0,
                  'totalPages': 2,
                  'totalElements': 13,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }

            return http.Response(
              jsonEncode({
                'content': _servicePage(startId: 11, count: 3),
                'page': 1,
                'totalPages': 2,
                'totalElements': 13,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('not found', 404);
        }),
      );

      await tester.pumpWidget(const MaterialApp(home: MainPage()));
      await tester.pumpAndSettle();

      expect(find.text('Pedido 1'), findsOneWidget);
      expect(find.text('Pedido 10'), findsOneWidget);
      expect(find.text('Pedido 11'), findsNothing);
      expect(find.text('Carregar mais'), findsOneWidget);

      await tester.ensureVisible(find.text('Carregar mais'));
      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();

      expect(_topOf(tester, 'Pedido 1'), lessThan(_topOf(tester, 'Pedido 10')));
      expect(
          _topOf(tester, 'Pedido 10'), lessThan(_topOf(tester, 'Pedido 11')));
      expect(find.text('Pedido 13'), findsOneWidget);
      expect(find.text('Carregar mais'), findsNothing);
    });

    testWidgets(
        'Cenario: Dado filtro por categoria, quando aplica filtros, entao exibe apenas pedidos correspondentes',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});

      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response(
              jsonEncode({
                'id': 1,
                'name': 'Ana',
                'timeChronos': 8,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (_isServiceListRequest(request)) {
            final categories =
                request.url.queryParametersAll['categories'] ?? const [];

            if (categories.contains('Pintura')) {
              return http.Response(
                jsonEncode({
                  'content': [
                    _serviceJson(
                      id: 10,
                      title: 'Pedido de pintura',
                      categories: const ['Pintura'],
                    ),
                  ],
                  'page': 0,
                  'totalPages': 1,
                  'totalElements': 1,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }

            return http.Response(
              jsonEncode({
                'content': [
                  _serviceJson(
                    id: 10,
                    title: 'Pedido de pintura',
                    categories: const ['Pintura'],
                  ),
                  _serviceJson(
                    id: 20,
                    title: 'Aula de matematica',
                    categories: const ['Ensino'],
                  ),
                ],
                'page': 0,
                'totalPages': 1,
                'totalElements': 2,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('not found', 404);
        }),
      );

      await tester.pumpWidget(const MaterialApp(home: MainPage()));
      await tester.pumpAndSettle();

      expect(find.text('Pedido de pintura'), findsOneWidget);
      expect(find.text('Aula de matematica'), findsOneWidget);

      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Pintura');
      await tester.tap(find.text('Aplicar Filtros'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido de pintura'), findsOneWidget);
      expect(find.text('Aula de matematica'), findsNothing);
    });

    testWidgets(
        'Cenario: Dado filtro com menos de dez resultados, quando aplica filtros, entao botao carregar mais fica oculto',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});

      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response(
              jsonEncode({
                'id': 1,
                'name': 'Ana',
                'timeChronos': 8,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (_isServiceListRequest(request)) {
            final page = int.parse(request.url.queryParameters['page'] ?? '0');
            final categories =
                request.url.queryParametersAll['categories'] ?? const [];

            if (categories.contains('Pintura')) {
              return http.Response(
                jsonEncode({
                  'content': [
                    _serviceJson(
                      id: 10,
                      title: 'Pedido de pintura',
                      categories: const ['Pintura'],
                    ),
                  ],
                  'page': 0,
                  'totalPages': 1,
                  'totalElements': 1,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }

            if (page == 0) {
              return http.Response(
                jsonEncode({
                  'content': [
                    _serviceJson(
                      id: 10,
                      title: 'Pedido de pintura',
                      categories: const ['Pintura'],
                    ),
                    _serviceJson(
                      id: 20,
                      title: 'Aula de matematica',
                      categories: const ['Ensino'],
                    ),
                  ],
                  'page': 0,
                  'totalPages': 2,
                  'totalElements': 3,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }

            return http.Response(
              jsonEncode({
                'content': [
                  _serviceJson(
                    id: 30,
                    title: 'Outra pintura',
                    categories: const ['Pintura'],
                  ),
                ],
                'page': 1,
                'totalPages': 2,
                'totalElements': 3,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('not found', 404);
        }),
      );

      await tester.pumpWidget(const MaterialApp(home: MainPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Pintura');
      await tester.tap(find.text('Aplicar Filtros'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido de pintura'), findsOneWidget);
      expect(find.text('Aula de matematica'), findsNothing);
      expect(find.text('Carregar mais'), findsNothing);
    });

    testWidgets(
        'Cenario: Dado mais de dez pedidos carregados, quando limpa filtros, entao volta a mostrar apenas os dez primeiros',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});

      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response(
              jsonEncode({
                'id': 1,
                'name': 'Ana',
                'timeChronos': 8,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (_isServiceListRequest(request)) {
            final page = int.parse(request.url.queryParameters['page'] ?? '0');

            if (page == 0) {
              return http.Response(
                jsonEncode({
                  'content': _servicePage(startId: 1, count: 10),
                  'page': 0,
                  'totalPages': 3,
                  'totalElements': 25,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }

            return http.Response(
              jsonEncode({
                'content': _servicePage(startId: 11, count: 10),
                'page': 1,
                'totalPages': 3,
                'totalElements': 25,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          return http.Response('not found', 404);
        }),
      );

      await tester.pumpWidget(const MaterialApp(home: MainPage()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Carregar mais'));
      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido 1'), findsOneWidget);
      expect(find.text('Pedido 10'), findsOneWidget);
      expect(find.text('Pedido 11'), findsOneWidget);
      expect(find.text('Pedido 20'), findsOneWidget);

      await tester.ensureVisible(find.text('Filtros'));
      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpar Filtros'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido 1'), findsOneWidget);
      expect(find.text('Pedido 10'), findsOneWidget);
      expect(find.text('Pedido 11'), findsNothing);
      expect(find.text('Pedido 20'), findsNothing);
      expect(find.text('Carregar mais'), findsOneWidget);
    });
  });
}

double _topOf(WidgetTester tester, String text) {
  return tester.getTopLeft(find.text(text)).dy;
}

bool _isServiceListRequest(http.Request request) {
  return request.url.path.endsWith('/service/get/all/CRIADO');
}

Map<String, dynamic> _serviceJson({
  required int id,
  required String title,
  List<String> categories = const [],
}) {
  return {
    'id': id,
    'title': title,
    'description': 'Descricao do pedido $id',
    'serviceImageUrl': '',
    'timeChronos': 2,
    'status': 'CRIADO',
    'userCreator': {
      'id': 1,
      'name': 'Ana',
      'email': 'ana@example.com',
    },
    'categories': categories.map((name) => {'name': name}).toList(),
    'deadline': '2026-06-01',
    'modality': 'REMOTO',
  };
}

List<Map<String, dynamic>> _servicePage({
  required int startId,
  required int count,
}) {
  return List.generate(count, (index) {
    final id = startId + index;
    return _serviceJson(id: id, title: 'Pedido $id');
  });
}
