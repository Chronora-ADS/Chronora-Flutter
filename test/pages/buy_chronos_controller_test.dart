import 'package:chronora/pages/buy_chronos/buy_chronos_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Funcionalidade: Compra de Chronos', () {
    test('Cenario: Dado saldo atual, quando compra Chronos, entao calcula subtotal, taxa de 10% e total', () {
      final controller = BuyChronosController(initialBalance: 250);
      addTearDown(controller.dispose);

      controller.updatePurchaseAmount('20');

      expect(controller.subtotal, 50.00);
      expect(controller.taxAmount, 5.00);
      expect(controller.totalAmount, 55.00);
      expect(controller.chronosAfterPurchase, 270);
      expect(controller.canProceed, isTrue);
    });

    test('Cenario: Dado saldo proximo ao limite, quando a compra passa de 300 Chronos, entao bloqueia a acao', () {
      final controller = BuyChronosController(initialBalance: 250);
      addTearDown(controller.dispose);

      controller.updatePurchaseAmount('51');

      expect(controller.isLimitExceeded, isTrue);
      expect(controller.canProceed, isFalse);
      expect(controller.errorMessage, contains('Limite'));
      expect(controller.errorMessage, contains('300'));
      expect(controller.errorMessage, contains('50 Chronos'));
    });
  });
}
