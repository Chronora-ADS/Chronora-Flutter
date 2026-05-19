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

          if (request.url.path.endsWith('/service/get/all')) {
            final page = int.parse(request.url.queryParameters['page'] ?? '0');

            if (page == 0) {
              return http.Response(
                jsonEncode({
                  'content': [
                    _serviceJson(id: 10, title: 'Primeiro pedido carregado'),
                    _serviceJson(id: 20, title: 'Segundo pedido carregado'),
                  ],
                  'page': 0,
                  'totalPages': 2,
                  'totalElements': 4,
                }),
                200,
                headers: {'content-type': 'application/json'},
              );
            }

            return http.Response(
              jsonEncode({
                'content': [
                  _serviceJson(id: 30, title: 'Terceiro pedido carregado'),
                  _serviceJson(id: 5, title: 'Quarto pedido carregado'),
                ],
                'page': 1,
                'totalPages': 2,
                'totalElements': 4,
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

      expect(_topOf(tester, 'Primeiro pedido carregado'),
          lessThan(_topOf(tester, 'Segundo pedido carregado')));

      await tester.ensureVisible(find.text('Carregar mais'));
      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();

      expect(_topOf(tester, 'Primeiro pedido carregado'),
          lessThan(_topOf(tester, 'Segundo pedido carregado')));
      expect(_topOf(tester, 'Segundo pedido carregado'),
          lessThan(_topOf(tester, 'Terceiro pedido carregado')));
      expect(_topOf(tester, 'Terceiro pedido carregado'),
          lessThan(_topOf(tester, 'Quarto pedido carregado')));
    });
  });
}

double _topOf(WidgetTester tester, String text) {
  return tester.getTopLeft(find.text(text)).dy;
}

Map<String, dynamic> _serviceJson({
  required int id,
  required String title,
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
    'categories': const [],
    'deadline': '2026-06-01',
    'modality': 'REMOTO',
  };
}
