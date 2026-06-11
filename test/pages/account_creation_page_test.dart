import 'package:chronora/pages/auth/account_creation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildPage() {
    return const MaterialApp(home: Scaffold(body: AccountCreationPage()));
  }

  group('Funcionalidade: Cadastro e validacao inicial', () {
    testWidgets(
        'Cenario: Dado um novo usuario, quando digita celular, entao a mascara brasileira e aplicada',
        (tester) async {
      await tester.pumpWidget(buildPage());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Numero de celular (com DDD)'),
        '11987654321',
      );

      expect(find.text('(11) 98765-4321'), findsOneWidget);
    });

    testWidgets(
        'Cenario: Dado dados de cadastro, quando a senha nao tem maiuscula, entao exibe erro de forca',
        (tester) async {
      await tester.pumpWidget(buildPage());

      await tester.enterText(find.widgetWithText(TextFormField, 'Nome completo'), 'Ana Silva');
      await tester.enterText(find.widgetWithText(TextFormField, 'E-mail'), 'ana@email.com');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Numero de celular (com DDD)'),
        '11987654321',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), 'senhafraca');
      await tester.enterText(find.widgetWithText(TextFormField, 'Confirmar Senha'), 'senhafraca');
      await tester.tap(find.text('Criar Conta').last);
      await tester.pump();

      expect(find.text('Senha deve conter pelo menos uma letra maiuscula'), findsOneWidget);
    });
  });
}
