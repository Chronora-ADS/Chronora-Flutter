import 'dart:convert';

import 'package:chronora/core/api/api_service.dart';
import 'package:chronora/pages/notification/notification_page.dart';
import 'package:chronora/widgets/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    ApiService.setClientForTesting(null);
  });

  group('Funcionalidade: notificacoes', () {
    testWidgets(
        'Cenario: Dado tela de notificacoes, quando abre menu, entao barra lateral inicia no topo',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response(
              jsonEncode({'id': 1, 'name': 'Ana', 'timeChronos': 8}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/notification/get/all')) {
            return http.Response(
              jsonEncode([]),
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
            child: NotificationPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pump();

      expect(tester.getTopLeft(find.byType(SideMenu)).dy, 0);
    });

    testWidgets(
        'Cenario: Dado mais de dez notificacoes, quando carrega mais, entao exibe o proximo lote',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response(
              jsonEncode({'id': 1, 'name': 'Ana', 'timeChronos': 8}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/notification/get/all')) {
            return http.Response(
              jsonEncode(List.generate(12, (index) {
                final position = index + 1;
                return _notificationJson(
                  id: position,
                  message: 'Notificacao $position',
                  minutesAgo: index,
                );
              })),
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
            child: NotificationPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notificacao 1'), findsOneWidget);
      expect(find.text('Notificacao 11'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Carregar mais'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();

      expect(find.text('Notificacao 11'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Notificacao 12'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Notificacao 12'), findsOneWidget);
      expect(find.text('Carregar mais'), findsNothing);
    });

    testWidgets(
        'Cenario: Dado resposta envelopada, quando abre notificacoes, entao lista itens do backend',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response(
              jsonEncode({'id': 1, 'name': 'Ana', 'timeChronos': 8}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/notification/get/all')) {
            return http.Response(
              jsonEncode({
                'data': {
                  'notification': [
                    {
                      'notificationId': 99,
                      'content': 'Nova notificacao do backend',
                      'createdAt': '2026-06-01T21:03:00',
                      'servicePost': {
                        'serviceId': 7,
                        'name': 'Pedido envelopado',
                        'serviceStatus': 'ACEITO',
                      },
                    },
                  ],
                },
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
            child: NotificationPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nova notificacao do backend'), findsOneWidget);
      expect(find.text('Pedido envelopado'), findsOneWidget);
      expect(find.text('Nenhuma notificacao encontrada.'), findsNothing);
    });

    testWidgets(
        'Cenario: Dado dez notificacoes, quando abre a tela, entao botao carregar mais fica oculto',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
      ApiService.setClientForTesting(
        MockClient((request) async {
          if (request.url.path.endsWith('/user/get')) {
            return http.Response(
              jsonEncode({'id': 1, 'name': 'Ana', 'timeChronos': 8}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }

          if (request.url.path.endsWith('/notification/get/all')) {
            return http.Response(
              jsonEncode(List.generate(10, (index) {
                final position = index + 1;
                return _notificationJson(
                  id: position,
                  message: 'Notificacao $position',
                  minutesAgo: index,
                );
              })),
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
            child: NotificationPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Notificacao 10'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Notificacao 10'), findsOneWidget);
      expect(find.text('Carregar mais'), findsNothing);
    });
  });
}

Map<String, dynamic> _notificationJson({
  required int id,
  required String message,
  required int minutesAgo,
}) {
  return {
    'id': id,
    'message': message,
    'notificationTime': DateTime(2026, 6, 1, 21, 3)
        .subtract(Duration(minutes: minutesAgo))
        .toIso8601String(),
    'service': {
      'id': id,
      'title': 'Pedido $id',
      'status': 'ACEITO',
    },
  };
}
