import 'package:chronora/core/api/api_service.dart';
import 'package:chronora/core/constants/app_routes.dart';
import 'package:chronora/widgets/side_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Funcionalidade: Menu e navegacao', () {
    testWidgets(
        'Cenario: Dado menu lateral aberto, quando acessa carteira e meus pedidos, entao executa as rotas corretas',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      var walletOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.myOrders: (_) => const Scaffold(body: Text('Meus pedidos rota')),
            AppRoutes.login: (_) => const Scaffold(body: Text('Login rota')),
          },
          home: Scaffold(
            body: SideMenu(
              onWalletPressed: () => walletOpened = true,
              userName: 'Ana',
              userRating: 4.5,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Carteira'));
      await tester.pump();
      expect(walletOpened, isTrue);

      await tester.tap(find.text('Meus pedidos'));
      await tester.pumpAndSettle();
      expect(find.text('Meus pedidos rota'), findsOneWidget);
    });

    testWidgets(
        'Cenario: Dado usuario autenticado, quando faz logout, entao limpa sessao local e volta ao login',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-local'});
      ApiService.setClientForTesting(
        MockClient((request) async => http.Response('', 200)),
      );
      addTearDown(() => ApiService.setClientForTesting(null));

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.login: (_) => const Scaffold(body: Text('Login rota')),
          },
          home: Scaffold(
            body: SideMenu(
              onWalletPressed: () {},
              userName: 'Ana',
              userRating: 4.5,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(find.text('Login rota'), findsOneWidget);
    });
  });
}
