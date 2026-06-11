import 'package:chronora/pages/sell_chronos/sell_chronos_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Funcionalidade: Venda de Chronos', () {
    test('Cenario: Dado saldo disponivel, quando vende Chronos, entao calcula taxa de 10% descontada', () {
      final controller = SellChronosController(initialBalance: 40);
      addTearDown(controller.dispose);

      controller.updateSellAmount('10');

      expect(controller.subtotal, 20.00);
      expect(controller.taxAmount, 2.00);
      expect(controller.totalAmount, 18.00);
      expect(controller.chronosAfterSale, 30);
      expect(controller.canProceed, isTrue);
    });

    test('Cenario: Dado venda maior que o saldo, quando informa quantidade invalida, entao exibe erro amigavel', () {
      final controller = SellChronosController(initialBalance: 40);
      addTearDown(controller.dispose);

      controller.updateSellAmount('41');

      expect(controller.canProceed, isFalse);
      expect(controller.errorMessage, 'Saldo insuficiente para vender 41 Chronos.');
    });
  });
}
