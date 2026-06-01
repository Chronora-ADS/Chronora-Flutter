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
        'Cenario: Dado texto na busca, quando nao confirma, entao pesquisa somente ao pressionar enter ou clicar na lupa',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
      final requestedUrls = <Uri>[];

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
            requestedUrls.add(request.url);
            final query = request.url.queryParameters['query'];

            if (query == 'Pintura') {
              return http.Response(
                jsonEncode({
                  'content': [
                    _serviceJson(id: 10, title: 'Resultado pelo enter'),
                  ],
                  'page': 0,
                  'totalPages': 1,
                  'totalElements': 1,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }

            if (query == 'Jardinagem') {
              return http.Response(
                jsonEncode({
                  'content': [
                    _serviceJson(id: 20, title: 'Resultado pela lupa'),
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
                  _serviceJson(id: 1, title: 'Pedido inicial'),
                ],
                'page': 0,
                'totalPages': 1,
                'totalElements': 1,
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

      expect(requestedUrls, hasLength(1));
      expect(find.text('Pedido inicial'), findsOneWidget);

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Pintura');
      await tester.pump(const Duration(milliseconds: 500));

      expect(requestedUrls, hasLength(1));
      expect(find.text('Pedido inicial'), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(requestedUrls, hasLength(2));
      expect(requestedUrls.last.queryParameters['query'], 'Pintura');
      expect(find.text('Resultado pelo enter'), findsOneWidget);

      await tester.enterText(searchField, 'Jardinagem');
      await tester.pump(const Duration(milliseconds: 500));

      expect(requestedUrls, hasLength(2));
      expect(find.text('Resultado pelo enter'), findsOneWidget);

      await tester.tap(find.byTooltip('Pesquisar'));
      await tester.pumpAndSettle();

      expect(requestedUrls, hasLength(3));
      expect(requestedUrls.last.queryParameters['query'], 'Jardinagem');
      expect(find.text('Resultado pela lupa'), findsOneWidget);
    });

    testWidgets(
        'Cenario: Dado data limite digitada, quando aplica filtros, entao formata e envia prazo ao backend',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
      final requestedUrls = <Uri>[];
      final futureDate = DateTime.now().add(const Duration(days: 30));

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
            requestedUrls.add(request.url);
            return http.Response(
              jsonEncode({
                'content': [
                  _serviceJson(id: 1, title: 'Pedido com prazo'),
                ],
                'page': 0,
                'totalPages': 1,
                'totalElements': 1,
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

      final deadlineField = find.byWidgetPredicate((widget) {
        return widget is TextField &&
            widget.decoration?.hintText == 'dd/mm/aaaa';
      });

      expect(deadlineField, findsOneWidget);
      expect(find.byTooltip('Abrir calendário'), findsOneWidget);

      await tester.enterText(deadlineField, _dateDigits(futureDate));
      await tester.pump();

      expect(find.text(_displayDate(futureDate)), findsOneWidget);

      await tester.tap(find.text('Aplicar Filtros'));
      await tester.pumpAndSettle();

      expect(
          requestedUrls.last.queryParameters['deadline'], _isoDate(futureDate));
    });

    testWidgets(
        'Cenario: Dado data limite passada, quando digita no filtro, entao campo fica invalido e nao aplica',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
      final requestedUrls = <Uri>[];
      final pastDate = DateTime.now().subtract(const Duration(days: 1));

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
            requestedUrls.add(request.url);
            return http.Response(
              jsonEncode({
                'content': [
                  _serviceJson(id: 1, title: 'Pedido inicial'),
                ],
                'page': 0,
                'totalPages': 1,
                'totalElements': 1,
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

      expect(requestedUrls, hasLength(1));

      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();

      final deadlineField = find.byWidgetPredicate((widget) {
        return widget is TextField &&
            widget.decoration?.hintText == 'dd/mm/aaaa';
      });

      await tester.enterText(deadlineField, _dateDigits(pastDate));
      await tester.pump();

      expect(find.text(_displayDate(pastDate)), findsOneWidget);
      expect(
        find.text('Altere para uma data atual ou futura.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Aplicar Filtros'));
      await tester.pumpAndSettle();

      expect(requestedUrls, hasLength(1));
      expect(find.text('Filtros'), findsWidgets);
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
        'Cenario: Dado filtro com acentuacao, quando escolhe tipo a distancia, entao envia modalidade remota ao backend',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
      final requestedUrls = <Uri>[];

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
            requestedUrls.add(request.url);
            return http.Response(
              jsonEncode({
                'content': [
                  _serviceJson(
                    id: 10,
                    title: 'Aula remota',
                    categories: const ['Educação'],
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

          return http.Response('not found', 404);
        }),
      );

      await tester.pumpWidget(const MaterialApp(home: MainPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Filtros'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('À distância'));
      await tester.tap(find.text('Aplicar Filtros'));
      await tester.pumpAndSettle();

      expect(requestedUrls.last.queryParameters['modality'], 'REMOTO');
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

String _dateDigits(DateTime date) {
  return [
    date.day.toString().padLeft(2, '0'),
    date.month.toString().padLeft(2, '0'),
    date.year.toString().padLeft(4, '0'),
  ].join();
}

String _displayDate(DateTime date) {
  return [
    date.day.toString().padLeft(2, '0'),
    date.month.toString().padLeft(2, '0'),
    date.year.toString().padLeft(4, '0'),
  ].join('/');
}

String _isoDate(DateTime date) {
  return [
    date.year.toString().padLeft(4, '0'),
    date.month.toString().padLeft(2, '0'),
    date.day.toString().padLeft(2, '0'),
  ].join('-');
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
