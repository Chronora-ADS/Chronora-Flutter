import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/router/auth_wrapper.dart';
import '../../../widgets/header.dart';
import '../../../widgets/side_menu.dart';
import '../../../widgets/wallet_modal.dart';
import 'buy_success_page.dart';

class BuyChronosController extends ChangeNotifier {
  static const double CHRONOS_PRICE = 2.50;
  static const double TAX_PERCENTAGE = 0.10;
  static const int MAX_CHRONOS_PER_ACCOUNT = 300;
  static const String TOOLTIP_TEXT =
      'O valor em Chronos é equivalente à 25% do valor de 1 hora do salário mínimo brasileiro. '
      'No final, é aplicada uma taxa de 10% sobre o subtotal.';

  int currentBalance = 0;
  int purchaseAmount = 0;
  String errorMessage = '';
  bool isLoading = false;
  bool isLoadingBalance = true;
  String selectedPaymentMethod = 'Cartão de Crédito';

  late TextEditingController amountController;

  BuyChronosController() {
    amountController = TextEditingController();
    _loadCurrentBalance();
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

  Future<void> _purchaseChronosBackend(int amount) async {
    final String? token = await _getToken();
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    try {
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

  double get subtotal => purchaseAmount * CHRONOS_PRICE;
  double get tax => subtotal * TAX_PERCENTAGE;
  double get taxAmount => tax;
  double get totalAmount => subtotal + tax;
  int get chronosAfterPurchase => currentBalance + purchaseAmount;

  bool get isLimitExceeded => chronosAfterPurchase > MAX_CHRONOS_PER_ACCOUNT;

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

    if (chronosAfterPurchase > MAX_CHRONOS_PER_ACCOUNT) {
      onError(
          'Limite máximo de $MAX_CHRONOS_PER_ACCOUNT Chronos por conta atingido!\n\n'
          'Você já possui $currentBalance Chronos e tentou comprar $amount.\n'
          'Máximo que você pode comprar: $maxPurchaseAmount Chronos');
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await _purchaseChronosBackend(amount);
      
      currentBalance = chronosAfterPurchase;
      purchaseAmount = 0;
      amountController.clear();
      isLoading = false;
      notifyListeners();
      
      onSuccess();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      onError('Erro ao processar compra: ${e.toString()}');
    }
  }

  void updatePurchaseAmount(String value) {
    errorMessage = '';

    if (value.isEmpty) {
      purchaseAmount = 0;
      notifyListeners();
      return;
    }

    try {
      int amount = int.parse(value);

      if (amount < 0) {
        errorMessage = 'A quantidade não pode ser negativa.';
        purchaseAmount = 0;
      } else if (amount == 0) {
        purchaseAmount = 0;
      } else {
        purchaseAmount = amount;
        
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

  void reset() {
    purchaseAmount = 0;
    errorMessage = '';
    isLoading = false;
    notifyListeners();
  }
}

class BuyChronosPage extends StatefulWidget {
  const BuyChronosPage({super.key});

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
          title: const Text(
            'Erro',
            style: TextStyle(color: AppColors.branco),
          ),
          content: Text(
            message,
            style: const TextStyle(color: AppColors.branco),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text(
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
                const SizedBox(
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
                    Row(
                      children: [
                        const Text(
                          'Total', 
                          style: TextStyle(
                            color: Colors.black, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(width: 6),
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
                      style: const TextStyle(
                        color: Color(0xFFC29503), 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

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
                      context.pop();
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
                                context.replaceNamed('buy-success', extra: {
                                  'chronosAmount': amount,
                                  'totalAmount': controller.totalAmount,
                                  'paymentMethod': controller.selectedPaymentMethod,
                                });
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
        Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthWrapper(
      child: ChangeNotifierProvider(
        create: (_) => BuyChronosController(),
        child: Scaffold(
          appBar: Header(onMenuPressed: _toggleDrawer),
          backgroundColor: const Color(0xFF0B0C0C),
          body: Stack(
            children: [
              _buildBackgroundImages(),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: _buildSearchBar(),
                  ),
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
      ),
    );
  }
}