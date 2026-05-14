import 'package:chronora/core/constants/app_routes.dart';
import 'package:chronora/widgets/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Funcionalidade: Protecao de rotas', () {
    testWidgets(
        'Cenario: Dado rota privada sem sessao, quando acessa direto, entao redireciona para login',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.profile,
          routes: {
            ...AppRoutes.routes,
            AppRoutes.login: (_) =>
                const Scaffold(body: Text('Login protegido')),
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Login protegido'), findsOneWidget);
    });

    testWidgets(
        'Cenario: Dado rota privada com sessao, quando acessa, entao mostra conteudo protegido',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-valido'});

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthGuard(
            child: Scaffold(body: Text('Conteudo privado')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Conteudo privado'), findsOneWidget);
    });

    testWidgets(
        'Cenario: Dado rota publica sem sessao, quando acessa, entao abre sem redirecionar',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.forgotPassword,
          routes: {
            ...AppRoutes.routes,
            AppRoutes.login: (_) =>
                const Scaffold(body: Text('Login protegido')),
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'E-mail'), findsOneWidget);
      expect(find.text('Login protegido'), findsNothing);
    });
  });
}
