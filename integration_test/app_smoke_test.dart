import 'package:chronora/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Funcionalidade: Smoke de autenticacao', () {
    testWidgets(
        'Cenario: Dado app sem sessao, quando inicia, entao abre login sem campo CPF',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const ChronoraFlutter());
      await tester.pumpAndSettle();

      expect(find.text('Bem vindo de volta!'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.textContaining('CPF'), findsNothing);
    });
  });
}
