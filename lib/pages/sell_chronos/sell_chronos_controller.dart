import 'package:flutter/material.dart';

/// Controller para vender Chronos
/// - Preço fixo de venda: R$2,00 por Chronos
/// - Taxa de 10% sobre o subtotal
/// - Validações: quantidade inteira >=1, <= saldo atual; chave PIX não vazia e formato básico
class SellChronosController extends ChangeNotifier {
  static const double CHRONOS_SELL_PRICE = 2.00; // R$ por Chronos
  static const double TAX_PERCENTAGE = 0.10; // 10%
  static const String TOOLTIP_TEXT =
      'O valor de venda de Chronos é equivalente a R\$2,00 reais. No final, é aplicada uma taxa de 10% sobre o total.';

  int currentBalance = 299; // saldo atual do usuário (pode ser carregado do backend)
  int sellAmount = 0;
  String pixKey = '';
  String errorMessage = '';
  bool isLoading = false;
  
  // Controllers
  late TextEditingController amountController;
  late TextEditingController pixKeyController;
  
  SellChronosController() {
    amountController = TextEditingController();
    pixKeyController = TextEditingController();
  }
  
  @override
  void dispose() {
    amountController.dispose();
    pixKeyController.dispose();
    super.dispose();
  }
  
  void initializeInitialValues() {
    amountController.clear();
    pixKeyController.clear();
    sellAmount = 0;
    pixKey = '';
    errorMessage = '';
    isLoading = false;
  }

  double get subtotal => sellAmount * CHRONOS_SELL_PRICE;
  double get tax => subtotal * TAX_PERCENTAGE;
  double get taxAmount => tax;
  double get totalAmount => subtotal - tax; // valor a receber pelo usuário
  int get chronosAfterSale => currentBalance - sellAmount;

  bool get isAmountValid => sellAmount > 0 && sellAmount <= currentBalance;
  bool get isPixValid => true; // PIX será validado em outra tela
  bool get canProceed => isAmountValid && !isLoading;
  
  void updateSellAmount(String value) {
    errorMessage = '';
    
    if (value.isEmpty) {
      sellAmount = 0;
      notifyListeners();
      return;
    }

    try {
      int amount = int.parse(value);
      
      if (amount < 0) {
        errorMessage = 'A quantidade não pode ser negativa.';
        sellAmount = 0;
      } else if (amount == 0) {
        sellAmount = 0;
      } else if (amount > currentBalance) {
        errorMessage = 'Saldo insuficiente para vender $amount Chronos.';
        sellAmount = amount;
      } else {
        sellAmount = amount;
      }
    } catch (e) {
      errorMessage = 'Digite apenas números inteiros.';
      sellAmount = 0;
    }
    
    notifyListeners();
  }
  
  void reset() {
    sellAmount = 0;
    pixKey = '';
    errorMessage = '';
    amountController.clear();
    pixKeyController.clear();
    notifyListeners();
  }
  
  void sellChronos({
    required int amount,
    required String pixKey,
    required Function onSuccess,
    required Function(String) onError,
  }) {
    if (amount <= 0) {
      onError('Quantidade inválida');
      return;
    }
    
    if (amount > currentBalance) {
      onError('Saldo insuficiente');
      return;
    }
    
    if (!_validatePixBasic(pixKey)) {
      onError('Chave PIX inválida');
      return;
    }
    
    isLoading = true;
    notifyListeners();
    
    Future.delayed(const Duration(milliseconds: 900), () {
      currentBalance = chronosAfterSale;
      sellAmount = 0;
      pixKey = '';
      amountController.clear();
      pixKeyController.clear();
      isLoading = false;
      notifyListeners();
      onSuccess();
    });
  }

  bool _validatePixBasic(String key) {
    if (key.isEmpty) return false;
    // Verificação simples: e-mail, CPF (somente números 11), telefone (10-13 dígitos) ou aleatória (chave aleatória allowed)
    final emailRegex = RegExp(r"^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}");
    final digitsOnly = RegExp(r"^[0-9]+$");
    final phoneRegex = RegExp(r'^\+?[0-9]{10,13}\$');

    if (emailRegex.hasMatch(key)) return true;
    final clean = key.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 11 && digitsOnly.hasMatch(clean)) return true; // possível CPF
    if (phoneRegex.hasMatch(key)) return true;
    // chave aleatória (UUID-like) allow alphanumeric between 8 and 64
    final randomKey = RegExp(r'^[a-zA-Z0-9_-]{8,64}\$');
    if (randomKey.hasMatch(key)) return true;

    return false;
  }

  /// Processa a venda (simulado)
  Future<void> processSale(BuildContext context) async {
    if (!canProceed) return;
    isLoading = true;
    notifyListeners();

    try {
      // Simular chamada HTTPS de confirmação da chave PIX e processamento
      await Future.delayed(const Duration(milliseconds: 900));

      // Atualiza saldo local
      currentBalance = chronosAfterSale;
      sellAmount = 0;
      pixKey = '';

      isLoading = false;
      notifyListeners();

      // Mostrar confirmação
      _showSuccessDialog(context);
    } catch (e) {
      errorMessage = 'Erro ao processar venda: $e';
      isLoading = false;
      notifyListeners();
    }
  }

  void cancelSale() {
    sellAmount = 0;
    pixKey = '';
    errorMessage = '';
    notifyListeners();
  }

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
          '✓ Venda realizada com sucesso!',
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
                color: const Color(0xFFE9EAEC).withValues(alpha: 0.7),
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

    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) Navigator.of(context).pop();
    });
  }
}
