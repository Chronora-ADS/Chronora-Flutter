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

      await tester.ensureVisible(find.text('Criar pedido'));
      await tester.tap(find.text('Criar pedido'));
      await tester.pump();
      expect(find.textContaining('obrigat'), findsWidgets);

      await tester.enterText(find.byType(TextFormField).at(1), 'Aula de violao');
      await tester.enterText(find.byType(TextFormField).at(2), 'descricao curta');
      await tester.ensureVisible(find.text('Criar pedido'));
      await tester.tap(find.text('Criar pedido'));
      await tester.pump();

      expect(find.text('A descricao deve ter pelo menos 20 palavras'), findsOneWidget);
    });
  });
}
