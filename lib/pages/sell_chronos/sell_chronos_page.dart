import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/header.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';
import 'pix_sell_page.dart';

/// Controller para vender Chronos
/// - Preço fixo de venda: R$2,00 por Chronos
/// - Taxa de 10% sobre o subtotal
/// - Validações: quantidade inteira >=1, <= saldo atual; chave PIX não vazia e formato básico
class SellChronosController extends ChangeNotifier {
  static const double CHRONOS_SELL_PRICE = 2.00; // R$ por Chronos
  static const double TAX_PERCENTAGE = 0.10; // 10%
  static const int MIN_CHRONOS_KEEP = 1; // Mínimo de Chronos que deve permanecer na carteira
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

  // REGRA: Não pode vender todos os Chronos - deve manter pelo menos MIN_CHRONOS_KEEP
  bool get isAmountValid => 
      sellAmount > 0 && 
      sellAmount <= currentBalance &&
      chronosAfterSale >= MIN_CHRONOS_KEEP;
  
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
      } else if (chronosAfterSale < MIN_CHRONOS_KEEP) {
        errorMessage = 'Você deve manter pelo menos $MIN_CHRONOS_KEEP Chronos em sua carteira.';
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
    
    if (chronosAfterSale < MIN_CHRONOS_KEEP) {
      onError('Você deve manter pelo menos $MIN_CHRONOS_KEEP Chronos em sua carteira.');
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

    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) Navigator.of(context).pop();
    });
  }
}

class SellChronosPageStyle {
  static const Color darkBg = Color(0xFF0B0C0C);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color accentYellow = Color(0xFFFFC300);
  static const Color textPrimary = Color(0xFFE9EAEC);
  static const Color textSecondary = Color(0xFFB5BFAE);
  static const Color borderGray = Color(0xFF2A2A2A);
  static const Color errorRed = Color(0xFFFF6B6B);

  static BoxDecoration cardDecoration() => BoxDecoration(
        color: darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static InputDecoration inputDecoration({
    required String label,
    required String hint,
    bool hasError = false,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: accentYellow,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: textSecondary.withOpacity(0.6),
          fontSize: 14,
        ),
        filled: true,
        fillColor: borderGray.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? errorRed : borderGray,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? errorRed : borderGray,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: accentYellow,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  static const TextStyle headerTitle = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'Roboto',
  );

  static const TextStyle calculationLabel = TextStyle(
    color: textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
  );

  static const TextStyle calculationValue = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Roboto',
  );

  static const TextStyle calculationTax = TextStyle(
    color: accentYellow,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Roboto',
  );

  static ButtonStyle cancelButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: borderGray.withOpacity(0.5),
        foregroundColor: textPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderGray, width: 1),
        ),
      );

  static ButtonStyle sellButtonStyle({required bool enabled}) =>
      ElevatedButton.styleFrom(
        backgroundColor: enabled ? accentYellow : accentYellow.withOpacity(0.3),
        foregroundColor: enabled ? darkBg : textSecondary.withOpacity(0.5),
        elevation: enabled ? 4 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );

  static const TextStyle errorText = TextStyle(
    color: errorRed,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
  );

  static const double paddingMedium = 16.0;
  static const double gapSmall = 8.0;
  static const double gapMedium = 12.0;
  static const double gapLarge = 16.0;
}

class SellChronosPage extends StatefulWidget {
  const SellChronosPage({Key? key}) : super(key: key);

  @override
  State<SellChronosPage> createState() => _SellChronosPageState();
}

class _SellChronosPageState extends State<SellChronosPage> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  late SellChronosController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SellChronosController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initializeInitialValues();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _openWallet() {
    setState(() {
      _isDrawerOpen = false;
      _isWalletOpen = true;
    });
  }

  void _closeWallet() {
    setState(() {
      _isWalletOpen = false;
    });
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.preto,
          title: Text(
            'Erro',
            style: TextStyle(color: AppColors.branco),
          ),
          content: Text(
            message,
            style: TextStyle(color: AppColors.branco),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(color: AppColors.amareloClaro),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBackgroundImages() {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 135,
          child: Image.asset(
            'assets/img/Comb2.png',
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Image.asset(
            'assets/img/BarAscending.png',
            width: 210.47,
            height: 178.9,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 60,
          child: Image.asset(
            'assets/img/Comb3.png',
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFFE9EAEC),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: 'Pintura de parede, aula de inglês...',
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.7),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFE9EAEC),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/img/Search.png',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.search, size: 20),
            ),
          ),
        ),
        onChanged: (value) {
          print('Texto da busca: $value');
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, SellChronosController controller) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EAEC),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Vender Chronos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Saldo atual
              Row(
                children: [
                  Text(
                    'Chronos atuais:',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset('assets/img/Coin.png', width: 18, height: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${controller.currentBalance}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Campo de quantidade
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EAEC),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller.amountController,
                  onChanged: controller.updateSellAmount,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Quantidade de venda',
                    hintStyle: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFE9EAEC),
                    errorStyle: const TextStyle(fontSize: 12, height: 0.1),
                  ),
                ),
              ),
              
              // Mensagem de erro
              if (controller.errorMessage.isNotEmpty) ...{
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              },

              const SizedBox(height: 15),

              // Resumo com borda amarela
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFC29503), width: 2),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFE9EAEC),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _labelValueRow('Subtotal', 'R\$ ${controller.subtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _labelValueRow('Taxa (10%)', 'R\$ ${controller.taxAmount.toStringAsFixed(2)}'),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Texto "Total a receber" com tooltip
                        Row(
                          children: [
                            Text(
                              'Total a receber', 
                              style: TextStyle(
                                color: Colors.black, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Tooltip com ponto de interrogação
                            Tooltip(
                              message: 'O valor de venda Chronos é equivalente à 20% de 10 reais. No final, é aplicado uma taxa de 10% sobre o total.',
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'R\$ ${controller.totalAmount.toStringAsFixed(2)}', 
                          style: TextStyle(
                            color: const Color(0xFFC29503), 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // Chronos pós-venda
              Row(
                children: [
                  Text('Chronos pós-venda:', style: TextStyle(color: Colors.black.withOpacity(0.7))),
                  const SizedBox(width: 8),
                  Image.asset('assets/img/Coin.png', width: 18, height: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${controller.chronosAfterSale}',
                    style: TextStyle(
                      color: controller.chronosAfterSale < SellChronosController.MIN_CHRONOS_KEEP ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Mensagem informativa sobre o mínimo
              if (controller.chronosAfterSale >= 0) ...{
                const SizedBox(height: 8),
                Text(
                  'Você deve manter pelo menos ${SellChronosController.MIN_CHRONOS_KEEP} Chronos em sua carteira.',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              },

              const SizedBox(height: 25),

              // Botões
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFC29503),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: () {
                          controller.reset();
                        },
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFFC29503),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: controller.canProceed 
                            ? const Color(0xFFC29503)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: controller.canProceed
                            ? () {
                                int amount = int.tryParse(controller.amountController.text) ?? 0;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PixSellPage(
                                      chronosAmount: amount,
                                      totalAmount: controller.totalAmount,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: Text(
                          'Continuar',
                          style: TextStyle(
                            color: controller.canProceed 
                                ? const Color(0xFFE9EAEC)
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _labelValueRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.black.withOpacity(0.7))),
        Text(value, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(onMenuPressed: _toggleDrawer),
      backgroundColor: const Color(0xFF0B0C0C),
      body: Stack(
        children: [
          // Background images
          _buildBackgroundImages(),
          
          // Main content - BARRA DE PESQUISA NO TOPO, CARD CENTRALIZADO
          Column(
            children: [
              // Barra de pesquisa no topo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildSearchBar(),
              ),
              
              // Card centralizado verticalmente no meio da tela
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildForm(context, _controller),
                  ),
                ),
              ),
            ],
          ),

          // Menu lateral
          if (_isDrawerOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: SideMenu(
                        onWalletPressed: _openWallet,
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleDrawer,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Modal da Carteira
          if (_isWalletOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: WalletModal(
                      onClose: _closeWallet,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}