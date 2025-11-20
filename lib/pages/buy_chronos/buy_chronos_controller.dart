import 'package:flutter/material.dart';

/// Controller para gerenciar a compra de Chronos
///
/// Responsabilidades:
/// - Cálculos em tempo real (subtotal, taxa, total)
/// - Validação de entrada
/// - Persistência de dados
/// - Integração com gateway de pagamento
class BuyChronosController extends ChangeNotifier {
  // Constantes de negócio
  static const double CHRONOS_PRICE = 2.50; // R$ por Chronos
  static const double TAX_PERCENTAGE = 0.10; // 10%
  static const int MAX_CHRONOS_PER_ACCOUNT = 300; // Limite máximo de Chronos
  static const String TOOLTIP_TEXT =
      'O valor em Chronos é equivalente à 25% do valor de 1 hora do salário mínimo brasileiro. '
      'No final, é aplicada uma taxa de 10% sobre o subtotal.';

  // Estado
  int currentBalance = 299; // Saldo atual do usuário
  int purchaseAmount = 0;
  String errorMessage = '';
  bool isLoading = false;
  String selectedPaymentMethod = 'Cartão de Crédito';

  // Controllers
  late TextEditingController amountController;

  BuyChronosController() {
    amountController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  void initializeInitialValues() {
    amountController.clear();
    purchaseAmount = 0;
    errorMessage = '';
    isLoading = false;
  }

  // Getters para cálculos
  double get subtotal => purchaseAmount * CHRONOS_PRICE;
  double get tax => subtotal * TAX_PERCENTAGE;
  double get taxAmount => tax;
  double get totalAmount => subtotal + tax;
  int get chronosAfterPurchase => currentBalance + purchaseAmount;

  // REGRA: Não pode comprar mais de 300 Chronos no total
  bool get isLimitExceeded => chronosAfterPurchase > MAX_CHRONOS_PER_ACCOUNT;

  // Quantidade máxima que pode comprar
  int get maxPurchaseAmount => MAX_CHRONOS_PER_ACCOUNT - currentBalance;

  bool get canProceed => purchaseAmount > 0 && !isLimitExceeded && !isLoading;

  void setPaymentMethod(String method) {
    selectedPaymentMethod = method;
    notifyListeners();
  }

  void purchaseChronos({
    required int amount,
    required Function onSuccess,
    required Function(String) onError,
  }) {
    if (amount <= 0) {
      onError('Quantidade inválida');
      return;
    }

    // REGRA: Verifica se ultrapassa o limite de 300 Chronos
    if (chronosAfterPurchase > MAX_CHRONOS_PER_ACCOUNT) {
      onError(
          'Limite máximo de $MAX_CHRONOS_PER_ACCOUNT Chronos por conta atingido!\n\n'
          'Você já possui $currentBalance Chronos e tentou comprar $amount.\n'
          'Máximo que você pode comprar: $maxPurchaseAmount Chronos');
      return;
    }

    // Simula processamento
    isLoading = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 800), () {
      currentBalance = chronosAfterPurchase;
      purchaseAmount = 0;
      amountController.clear();
      isLoading = false;
      notifyListeners();
      onSuccess(); // ← Dispara a navegação para a tela de sucesso
    });
  }

  /// Atualiza a quantidade inserida pelo usuário
  /// Valida em tempo real e atualiza estado
  void updatePurchaseAmount(String value) {
    errorMessage = '';

    // Trata entrada vazia ou inválida
    if (value.isEmpty) {
      purchaseAmount = 0;
      notifyListeners();
      return;
    }

    // Tenta converter para inteiro
    try {
      int amount = int.parse(value);

      // Valida quantidade
      if (amount < 0) {
        errorMessage = 'A quantidade não pode ser negativa.';
        purchaseAmount = 0;
      } else if (amount == 0) {
        purchaseAmount = 0;
      } else if (isLimitExceeded) {
        errorMessage =
            'Limite máximo de $MAX_CHRONOS_PER_ACCOUNT Chronos atingido!\n'
            'Máximo que você pode comprar: $maxPurchaseAmount Chronos';
        purchaseAmount = amount;
      } else {
        purchaseAmount = amount;
      }
    } catch (e) {
      errorMessage = 'Digite apenas números inteiros.';
      purchaseAmount = 0;
    }

    notifyListeners();
  }

  /// Processa a compra e redireciona para gateway
  /// Em produção, integrar com Mercado Pago ou PagSeguro
  Future<void> processPurchase(BuildContext context) async {
    if (!canProceed) return;

    isLoading = true;
    notifyListeners();

    try {
      // Simula chamada ao backend para registrar compra
      await Future.delayed(const Duration(milliseconds: 800));

      // Atualiza saldo local
      currentBalance = chronosAfterPurchase;
      purchaseAmount = 0;

      isLoading = false;
      notifyListeners();

      // Aqui redirecionaria para gateway real (Mercado Pago/PagSeguro)
      // Por enquanto, mostra sucesso
      _showSuccessDialog(context);
    } catch (e) {
      errorMessage = 'Erro ao processar compra: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  /// Cancela a operação
  void cancelPurchase() {
    purchaseAmount = 0;
    errorMessage = '';
    notifyListeners();
  }

  /// Mostra diálogo de sucesso
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFFC300), width: 2),
        ),
        title: const Text(
          '✓ Compra realizada com sucesso!',
          style: TextStyle(
            color: Color(0xFFFFC300),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Novo saldo: 🕰️ $currentBalance Chronos',
              style: const TextStyle(
                color: Color(0xFFE9EAEC),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Você será redirecionado em 3 segundos...',
              style: TextStyle(
                color: const Color(0xFFE9EAEC).withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Fechar',
              style: TextStyle(color: Color(0xFFFFC300)),
            ),
          ),
        ],
      ),
    );

    // Auto-close após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  /// Reseta o estado da compra
  void reset() {
    purchaseAmount = 0;
    errorMessage = '';
    isLoading = false;
    notifyListeners();
  }
}
