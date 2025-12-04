import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import '../../widgets/header.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';
import 'buy_success_page.dart';

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
  int currentBalance = 0; // Inicializa com 0, será carregado do backend
  int purchaseAmount = 0;
  String errorMessage = '';
  bool isLoading = false;
  bool isLoadingBalance = true; // Novo estado para carregamento do saldo
  String selectedPaymentMethod = 'Cartão de Crédito';

  // Controllers
  late TextEditingController amountController;

  BuyChronosController() {
    amountController = TextEditingController();
    _loadCurrentBalance(); // Carrega saldo ao criar controller
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Carrega o saldo atual do usuário do backend
  Future<void> _loadCurrentBalance() async {
    try {
      final String? token = await _getToken();

      if (token == null) {
        _updateState(() {
          isLoadingBalance = false;
          currentBalance = 0;
        });
        return;
      }

      final response = await ApiService.get('/user/get', token: token);

      if (response.statusCode == 200) {
        final userData = _parseResponse(response.body);
        _updateState(() {
          currentBalance = userData['timeChronos'] ?? 0;
          isLoadingBalance = false;
        });
      } else {
        _updateState(() {
          isLoadingBalance = false;
          currentBalance = 0;
        });
      }
    } catch (error) {
      _updateState(() {
        isLoadingBalance = false;
        currentBalance = 0;
      });
    }
  }

  /// Faz a requisição PUT para comprar Chronos
  Future<void> _purchaseChronosBackend(int amount) async {
    final String? token = await _getToken();
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    try {
      // Faz a requisição PUT com o header "Chronos" contendo a quantidade
      final response = await ApiService.putWithHeaders(
        '/user/put/buy-chronos',
        {
          'Chronos': amount.toString(),
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Erro ao processar compra';
        throw Exception(errorMessage);
      }
    } catch (error) {
      rethrow;
    }
  }

  Map<String, dynamic> _parseResponse(String responseBody) {
    try {
      final jsonData = json.decode(responseBody);
      if (jsonData is Map<String, dynamic>) {
        final chronos = jsonData['timeChronos'] ?? 0;
        return {'timeChronos': chronos};
      }
      return {'timeChronos': 0};
    } catch (e) {
      return {'timeChronos': 0};
    }
  }

  void _updateState(void Function() callback) {
    callback();
    notifyListeners();
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

  bool get canProceed => purchaseAmount > 0 && !isLimitExceeded && !isLoading && !isLoadingBalance;

  void setPaymentMethod(String method) {
    selectedPaymentMethod = method;
    notifyListeners();
  }

  Future<void> purchaseChronos({
    required int amount,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
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

    // Inicia o processamento
    isLoading = true;
    notifyListeners();

    try {
      // Faz a requisição PUT para o backend
      await _purchaseChronosBackend(amount);
      
      // Atualiza o saldo local após sucesso
      currentBalance = chronosAfterPurchase;
      purchaseAmount = 0;
      amountController.clear();
      isLoading = false;
      notifyListeners();
      
      onSuccess(); // ← Dispara a navegação para a tela de sucesso
    } catch (e) {
      isLoading = false;
      notifyListeners();
      onError('Erro ao processar compra: ${e.toString()}');
    }
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
      } else {
        // Atualiza o valor
        purchaseAmount = amount;
        
        // AGORA verifica o limite com o NOVO valor
        if (chronosAfterPurchase > MAX_CHRONOS_PER_ACCOUNT) {
          errorMessage =
              'Limite máximo de $MAX_CHRONOS_PER_ACCOUNT Chronos por conta!\n\n'
              'Você já possui $currentBalance Chronos e tentou comprar $amount.\n'
              'Máximo que você pode comprar: $maxPurchaseAmount Chronos';
        }
      }
    } catch (e) {
      errorMessage = 'Digite apenas números inteiros.';
      purchaseAmount = 0;
    }

    notifyListeners();
  }

  /// Reseta o estado da compra
  void reset() {
    purchaseAmount = 0;
    errorMessage = '';
    isLoading = false;
    notifyListeners();
  }
}

/// Estilos e tema da tela de compra de Chronos
/// 
/// Implementa tema escuro moderno com amarelo dourado vibrante
class BuyChronosPageStyle {
  // Cores do tema
  static const Color darkBg = Color(0xFF0B0C0C); // Preto profundo
  static const Color darkCard = Color(0xFF1A1A1A); // Cinza muito escuro
  static const Color accentYellow = Color(0xFFFFC300); // Amarelo vibrante
  static const Color lightYellow = Color(0xFFFFC300); // Amarelo claro (accent)
  static const Color textPrimary = Color(0xFFE9EAEC); // Branco off
  static const Color textSecondary = Color(0xFFB5BFAE); // Cinza
  static const Color borderGray = Color(0xFF2A2A2A); // Borda cinza
  static const Color errorRed = Color(0xFFFF6B6B); // Vermelho erro
  static const Color successGreen = Color(0xFF51CF66); // Verde sucesso

  // Padrão de hexágonos translúcidos (via Container com BoxDecoration)
  static const String hexagonPattern = 'assets/patterns/hexagon-pattern.svg';

  // ========== HEADER STYLES ==========
  static BoxDecoration headerDecoration() => BoxDecoration(
    color: darkCard,
    border: Border(
      bottom: BorderSide(color: borderGray, width: 1),
    ),
  );

  static const TextStyle headerTitle = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'Roboto',
  );

  static const TextStyle headerChronos = TextStyle(
    color: accentYellow,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Roboto',
  );

  // ========== SEARCH BAR STYLES ==========
  static InputDecoration searchBarDecoration() => InputDecoration(
    hintText: 'Pintura de parede, aula de inglês...',
    hintStyle: TextStyle(
      color: textSecondary.withOpacity(0.6),
      fontSize: 14,
    ),
    prefixIcon: Icon(
      Icons.search,
      color: accentYellow.withOpacity(0.7),
    ),
    filled: true,
    fillColor: borderGray.withOpacity(0.3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderGray, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderGray, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: accentYellow, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  // ========== CARD STYLES ==========
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

  static BoxDecoration calculationSectionDecoration() => BoxDecoration(
    color: darkBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: accentYellow, width: 1.5),
  );

  // ========== INPUT FIELD STYLES ==========
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
          color: textSecondary.withOpacity(0.5),
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

  // ========== CALCULATION TEXT STYLES ==========
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

  static const TextStyle calculationTotal = TextStyle(
    color: accentYellow,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    fontFamily: 'Roboto',
  );

  static const TextStyle chronosBalance = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
  );

  // ========== BUTTON STYLES ==========
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

  static ButtonStyle purchaseButtonStyle({required bool enabled}) =>
      ElevatedButton.styleFrom(
        backgroundColor: enabled ? accentYellow : accentYellow.withOpacity(0.3),
        foregroundColor: enabled ? darkBg : textSecondary.withOpacity(0.5),
        elevation: enabled ? 4 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );

  // ========== ERROR STYLES ==========
  static const TextStyle errorText = TextStyle(
    color: errorRed,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
  );

  // ========== TOOLTIP STYLES ==========
  static const TextStyle tooltipText = TextStyle(
    color: darkBg,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
    height: 1.4,
  );

  // ========== SPACING & LAYOUT ==========
  static const double paddingXs = 8.0;
  static const double paddingSmall = 12.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXl = 32.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  static const double gapSmall = 8.0;
  static const double gapMedium = 12.0;
  static const double gapLarge = 16.0;
  static const double gapXl = 24.0;
}

class BuyChronosPage extends StatefulWidget {
  const BuyChronosPage({Key? key}) : super(key: key);

  @override
  State<BuyChronosPage> createState() => _BuyChronosPageState();
}

class _BuyChronosPageState extends State<BuyChronosPage> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BuyChronosController>(context, listen: false)
          .initializeInitialValues();
    });
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

  Widget _buildForm(BuildContext context, BuyChronosController controller) {
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
              'Comprar Chronos',
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
              if (controller.isLoadingBalance)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              else
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
              onChanged: controller.isLoadingBalance ? null : controller.updatePurchaseAmount,
              enabled: !controller.isLoadingBalance,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: controller.isLoadingBalance ? 'Carregando saldo...' : 'Quantidade de compra',
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
          
          // Mensagem de erro - APENAS QUANDO TENTA COMPRAR MAIS DO QUE PODE
          if (controller.errorMessage.isNotEmpty) ...{
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Text(
                controller.errorMessage,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
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
                    // Texto "Total" com tooltip
                    Row(
                      children: [
                        Text(
                          'Total', 
                          style: TextStyle(
                            color: Colors.black, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Tooltip com ponto de interrogação
                        Tooltip(
                          message: 'O valor de compra de Chronos é equivalente à 25% de 10 reais. No final, é aplicado uma taxa de 10% sobre o total.',
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

          // Chronos pós-compra
          Row(
            children: [
              Text('Chronos pós-compra:', style: TextStyle(color: Colors.black.withOpacity(0.7))),
              const SizedBox(width: 8),
              Image.asset('assets/img/Coin.png', width: 18, height: 18),
              const SizedBox(width: 6),
              Text(
                '${controller.chronosAfterPurchase}',
                style: TextStyle(
                  color: controller.isLimitExceeded ? Colors.red : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

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
                      // Volta para a página anterior
                      Navigator.pop(context);
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
                        ? () async {
                            int amount = int.tryParse(controller.amountController.text) ?? 0;
                            await controller.purchaseChronos(
                              amount: amount,
                              onSuccess: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BuySuccessPage(
                                      chronosAmount: amount,
                                      totalAmount: controller.totalAmount,
                                      paymentMethod: controller.selectedPaymentMethod,
                                    ),
                                  ),
                                );
                              },
                              onError: (err) {
                                showErrorDialog(err);
                              },
                            );
                          }
                        : null,
                    child: Text(
                      'Finalizar compra',
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
      body: ChangeNotifierProvider(
        create: (_) => BuyChronosController(),
        child: Stack(
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
                      child: Consumer<BuyChronosController>(
                        builder: (context, controller, child) {
                          return _buildForm(context, controller);
                        },
                      ),
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
      ),
    );
  }
}