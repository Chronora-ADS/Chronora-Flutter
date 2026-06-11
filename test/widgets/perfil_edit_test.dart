import 'package:chronora/core/models/user_model.dart';
import 'package:chronora/widgets/perfil_edit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final args = {
    'user': User(
      id: '1',
      name: 'Ana Silva',
      email: 'ana@email.com',
      phoneNumber: '(11) 98765-4321',
      timeChronos: 25,
    ),
    'onProfileUpdated': () {},
  };

  Widget buildPage() {
    return MaterialApp(
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        settings: RouteSettings(arguments: args),
        builder: (_) => const PerfilEdit(),
      ),
    );
  }

  group('Funcionalidade: Perfil', () {
    testWidgets(
        'Cenario: Dado tela de perfil, quando senha atual nao foi informada, entao atualizar perfil fica desabilitado',
        (tester) async {
      await tester.pumpWidget(buildPage());

      final button = find.widgetWithText(ElevatedButton, 'Atualizar perfil');
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

      await tester.enterText(find.byType(TextField).at(3), 'SenhaAtual1');
      await tester.pump();

      expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
    });

    testWidgets(
        'Cenario: Dado usuario no perfil, quando toca em deletar conta, entao modal de confirmacao abre e pode cancelar',
        (tester) async {
      await tester.pumpWidget(buildPage());

      await tester.ensureVisible(find.text('Deletar conta'));
      await tester.tap(find.text('Deletar conta'));
      await tester.pumpAndSettle();

      expect(find.text('Deletar Conta'), findsOneWidget);
      expect(find.textContaining('Tem certeza'), findsOneWidget);

      await tester.tap(find.text('Cancelar').last);
      await tester.pumpAndSettle();

      expect(find.text('Deletar Conta'), findsNothing);
    });
  });
}
