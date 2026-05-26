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
  });
}
