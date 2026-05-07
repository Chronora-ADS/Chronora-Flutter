import 'dart:convert';

import 'package:chronora/core/api/api_service.dart';
import 'package:chronora/core/constants/app_routes.dart';
import 'package:chronora/main.dart';
import 'package:chronora/pages/auth/forgot_password_page.dart';
import 'package:chronora/pages/auth/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    ApiService.setClientForTesting(null);
  });

  group('Funcionalidade: Recuperacao de senha', () {
    testWidgets(
        'Cenario: Dado e-mail valido, quando solicita recuperacao, entao envia redirect para nova senha',
        (tester) async {
      late Map<String, dynamic> payload;
      ApiService.setClientForTesting(
        MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 200);
        }),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-mail'),
        'ana@chronora.com',
      );
      await tester.tap(find.text('Enviar'));
      await tester.pumpAndSettle();

      expect(payload['email'], 'ana@chronora.com');
      expect(payload['redirectTo'], isNot(contains('/#/reset-password')));
      expect(payload['redirectTo'], isNotEmpty);
    });

    testWidgets(
        'Cenario: Dado link de recuperacao, quando informa nova senha, entao redefine com token',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'sessao-antiga'});

      late String? authorization;
      late Map<String, dynamic> payload;
      ApiService.setClientForTesting(
        MockClient((request) async {
          authorization = request.headers['Authorization'];
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('', 200);
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.login: (_) => const Scaffold(body: Text('Login')),
          },
          home: const ResetPasswordPage(accessToken: 'recovery-token'),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nova senha'),
        'SenhaNova1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar senha'),
        'SenhaNova1',
      );
      await tester.tap(find.text('Redefinir senha'));
      await tester.pumpAndSettle();

      expect(authorization, 'Bearer recovery-token');
      expect(payload, {'newPassword': 'SenhaNova1'});
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets(
        'Cenario: Dado token de recuperacao na URL inicial, quando app abre, entao mostra tela de nova senha',
        (tester) async {
      await tester.pumpWidget(
        ChronoraFlutter(
          initialUri: Uri.parse(
            'http://localhost:3000/#access_token=recovery-token&type=recovery',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nova senha'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'Nova senha'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Confirmar senha'),
        findsOneWidget,
      );
    });
  });
}
