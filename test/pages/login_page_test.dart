import 'dart:convert';

import 'package:chronora/core/api/api_service.dart';
import 'package:chronora/core/constants/app_routes.dart';
import 'package:chronora/pages/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    ApiService.setClientForTesting(null);
  });

  Widget buildLoginApp() {
    return MaterialApp(
      routes: {
        AppRoutes.main: (_) => const Scaffold(body: Text('Pagina inicial')),
        AppRoutes.accountCreation: (_) => const Scaffold(body: Text('Cadastro')),
        AppRoutes.forgotPassword: (_) =>
            const Scaffold(body: Text('Recuperar senha')),
      },
      home: const LoginPage(),
    );
  }

  group('Funcionalidade: Login', () {
    testWidgets(
        'Cenario: Dado e-mail ou username e senha, quando faz login, entao autentica sem enviar CPF',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      late Map<String, dynamic> payload;
      ApiService.setClientForTesting(
        MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(
            jsonEncode({'token': 'access-token'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await tester.pumpWidget(buildLoginApp());
      await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'ana.usuario');
      await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'SenhaForte1');
      await tester.tap(find.text('Entrar').last);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(payload, {'email': 'ana.usuario', 'password': 'SenhaForte1'});
      expect(payload.containsKey('cpf'), isFalse);
      expect(find.text('Pagina inicial'), findsOneWidget);
    });

    testWidgets(
        'Cenario: Dado falha de conexao com backend, quando tenta entrar, entao mostra mensagem amigavel',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      ApiService.setClientForTesting(
        MockClient((request) async => throw Exception('Supabase indisponivel')),
      );

      await tester.pumpWidget(buildLoginApp());
      await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'ana@email.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'SenhaForte1');
      await tester.tap(find.text('Entrar').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Erro de conexao'), findsOneWidget);
    });
  });
}
