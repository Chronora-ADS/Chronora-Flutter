import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/router/auth_wrapper.dart';
import '../../../widgets/header.dart';
import '../../../widgets/side_menu.dart';
import '../../../widgets/wallet_modal.dart';
import 'pix_sell_page.dart';

class SellChronosController extends ChangeNotifier {
  static const double CHRONOS_SELL_PRICE = 2.00;
  static const double TAX_PERCENTAGE = 0.10;
  static const int MIN_CHRONOS_KEEP = 1;
  static const String TOOLTIP_TEXT =
      'O valor de venda de Chronos é equivalente a R\$2,00 reais. No final, é aplicada uma taxa de 10% sobre o total.';

  int currentBalance = 0;
  int sellAmount = 0;
  String pixKey = '';
  String errorMessage = '';
  bool isLoading = false;
  bool isLoadingBalance = true;
  
  late TextEditingController amountController;
  late TextEditingController pixKeyController;
  
  SellChronosController() {
    amountController = TextEditingController();
    pixKeyController = TextEditingController();
    _loadCurrentBalance();
  }
  
  @override
  void dispose() {
    amountController.dispose();
    pixKeyController.dispose();
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
    pixKeyController.clear();
    sellAmount = 0;
    pixKey = '';
    errorMessage = '';
    isLoading = false;
  }

  double get subtotal => sellAmount * CHRONOS_SELL_PRICE;
  double get tax => subtotal * TAX_PERCENTAGE;
  double get taxAmount => tax;
  double get totalAmount => subtotal - tax;
  int get chronosAfterSale => currentBalance - sellAmount;

  bool get isAmountValid => 
      sellAmount > 0 && 
      sellAmount <= currentBalance &&
      chronosAfterSale >= MIN_CHRONOS_KEEP;
  
  bool get isPixValid => true;
  bool get canProceed => isAmountValid && !isLoading && !isLoadingBalance;
  
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
  
  Future<void> sellChronos({
    required int amount,
    required String pixKey,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
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
    
    try {
      await Future.delayed(const Duration(milliseconds: 900));
      
      currentBalance = chronosAfterSale;
      sellAmount = 0;
      pixKey = '';
      amountController.clear();
      pixKeyController.clear();
      isLoading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      onError('Erro ao processar venda: ${e.toString()}');
    }
  }

  bool _validatePixBasic(String key) {
    if (key.isEmpty) return false;
    final emailRegex = RegExp(r"^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}");
    final digitsOnly = RegExp(r"^[0-9]+$");
    final phoneRegex = RegExp(r'^\+?[0-9]{10,13}\$');

    if (emailRegex.hasMatch(key)) return true;
    final clean = key.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 11 && digitsOnly.hasMatch(clean)) return true;
    if (phoneRegex.hasMatch(key)) return true;
    final randomKey = RegExp(r'^[a-zA-Z0-9_-]{8,64}\$');
    if (randomKey.hasMatch(key)) return true;

    return false;
  }
}

class SellChronosPage extends StatefulWidget {
  const SellChronosPage({super.key});

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

  Widget _buildForm(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
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
                  if (_controller.isLoadingBalance)
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
                      '${_controller.currentBalance}',
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
                  controller: _controller.amountController,
                  onChanged: _controller.isLoadingBalance ? null : _controller.updateSellAmount,
                  enabled: !_controller.isLoadingBalance,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: _controller.isLoadingBalance ? 'Carregando saldo...' : 'Quantidade de venda',
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
              
              if (_controller.errorMessage.isNotEmpty) ...{
                const SizedBox(height: 8),
                Text(
                  _controller.errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
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
                    _labelValueRow('Subtotal', 'R\$ ${_controller.subtotal.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _labelValueRow('Taxa (10%)', 'R\$ ${_controller.taxAmount.toStringAsFixed(2)}'),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Total a receber', 
                              style: TextStyle(
                                color: Colors.black, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            const SizedBox(width: 6),
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
                          'R\$ ${_controller.totalAmount.toStringAsFixed(2)}', 
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
                  Text('Chronos pós-venda:', style: TextStyle(color: Colors.black.withOpacity(0.7))),
                  const SizedBox(width: 8),
                  Image.asset('assets/img/Coin.png', width: 18, height: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_controller.chronosAfterSale}',
                    style: TextStyle(
                      color: _controller.chronosAfterSale < SellChronosController.MIN_CHRONOS_KEEP ? Colors.red : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              if (_controller.chronosAfterSale >= 0) ...{
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
                        color: _controller.canProceed 
                            ? const Color(0xFFC29503)
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: _controller.canProceed
                            ? () {
                                int amount = int.tryParse(_controller.amountController.text) ?? 0;
                                context.pushNamed('pix-sell', extra: {
                                  'chronosAmount': amount,
                                  'totalAmount': _controller.totalAmount,
                                });
                              }
                            : null,
                        child: Text(
                          'Continuar',
                          style: TextStyle(
                            color: _controller.canProceed 
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
        Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthWrapper(
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
                      child: _buildForm(context),
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
    );
  }
}