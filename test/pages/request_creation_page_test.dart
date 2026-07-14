import 'package:chronora/core/models/service_tracking_type.dart';
import 'package:chronora/pages/requests/request-creator-editor/request_creation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Funcionalidade: Criacao e edicao de pedidos', () {
    testWidgets(
      'Cenario: Dado formulario de pedido, quando titulo esta vazio ou descricao e curta, entao valida os campos',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(const MaterialApp(home: RequestCreationPage()));

        final createButton = find.ancestor(
          of: find.text('Criar pedido'),
          matching: find.byType(TextButton),
        );

        await tester.ensureVisible(createButton);
        await tester.tap(createButton, warnIfMissed: false);
        await tester.pump();
        expect(find.textContaining('obrigat'), findsWidgets);

        await tester.enterText(
          find.byType(TextFormField).at(1),
          'Aula de violao',
        );
        await tester.enterText(
          find.byType(TextFormField).at(2),
          'descricao curta',
        );
        await tester.ensureVisible(createButton);
        await tester.tap(createButton, warnIfMissed: false);
        await tester.pump();

        expect(find.textContaining('descricao'), findsWidgets);
      },
    );

    testWidgets(
      'Cenario: Dado formulario de pedido, quando adiciona mais de dez categorias, entao bloqueia a categoria excedente',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(const MaterialApp(home: RequestCreationPage()));

        final categoryField = find.widgetWithText(
          TextFormField,
          'Categoria(s) - Pressione Enter para adicionar',
        );
        await tester.ensureVisible(categoryField);

        for (var index = 1; index <= 10; index++) {
          await tester.tap(categoryField);
          await tester.enterText(categoryField, 'Categoria $index');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump();
        }

        expect(find.text('Categoria 10'), findsOneWidget);

        await tester.tap(categoryField);
        await tester.enterText(categoryField, 'Categoria 11');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(find.text('Limite de 10 categorias atingido'), findsOneWidget);
      },
    );

    testWidgets(
      'Cenario: Quando seleciona tipo de progresso, exibe marcos prontos e campo manual',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        await tester.pumpWidget(const MaterialApp(home: RequestCreationPage()));

        final trackingDropdown = find.byType(
          DropdownButtonFormField<ServiceTrackingType>,
        );
        await tester.ensureVisible(trackingDropdown);
        expect(find.text('Como o progresso será medido?'), findsOneWidget);

        await tester.tap(trackingDropdown);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Por tempo').last);
        await tester.pumpAndSettle();

        final milestoneDropdown =
            find.byType(DropdownButtonFormField<String>).last;
        expect(milestoneDropdown, findsOneWidget);

        await tester.tap(milestoneDropdown);
        await tester.pumpAndSettle();
        expect(find.text('10% por hora'), findsOneWidget);
        expect(find.text('Marco diferente'), findsOneWidget);

        await tester.tap(find.text('Marco diferente').last);
        await tester.pumpAndSettle();

        expect(
          find.text('Descreva como deseja medir este marco'),
          findsOneWidget,
        );
      },
    );
  });
}
