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
import 'sell_success_page.dart';

class PixSellPage extends StatefulWidget {
  final int chronosAmount;
  final double totalAmount;

  const PixSellPage({
    super.key,
    required this.chronosAmount,
    required this.totalAmount,
  });

  @override
  State<PixSellPage> createState() => _PixSellPageState();
}

class _PixSellPageState extends State<PixSellPage> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  late TextEditingController _pixKeyController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pixKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _pixKeyController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _sellChronosBackend(int amount, String pixKey) async {
    final String? token = await _getToken();
    
    if (token == null) {
      throw Exception('Token de autenticação não encontrado');
    }

    try {
      final response = await ApiService.putWithHeaders(
        '/user/put/sell-chronos',
        {
          'Chronos': amount.toString(),
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Erro ao processar venda';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception('Erro ${response.statusCode}: ${response.body}');
        }
      }
    } catch (error) {
      rethrow;
    }
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

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC29503), width: 2),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF8F9FA),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Resumo da Venda',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _labelValueRow('Chronos vendidos', '${widget.chronosAmount}'),
                const SizedBox(height: 8),
                _labelValueRow('Valor a receber', 'R\$ ${widget.totalAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                _labelValueRow('Taxa (10%)', 'R\$ ${(widget.totalAmount * 0.1).toStringAsFixed(2)}'),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Informar chave PIX',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),

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
              controller: _pixKeyController,
              onChanged: (value) {
                setState(() {});
              },
              enabled: !_isProcessing,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: _isProcessing ? 'Processando venda...' : 'Digite sua chave PIX (CPF, e-mail, telefone, chave aleatória)',
                hintStyle: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFE9EAEC),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Tipos de chave aceitos: CPF, e-mail, telefone ou chave aleatória',
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _isProcessing || _pixKeyController.text.isEmpty
                  ? null
                  : () async {
                      final pixKey = _pixKeyController.text;
                      if (_validatePixKey(pixKey)) {
                        setState(() {
                          _isProcessing = true;
                        });
                        
                        try {
                          await _sellChronosBackend(widget.chronosAmount, pixKey);
                          
                          context.replaceNamed('sell-success', extra: {
                            'chronosAmount': widget.chronosAmount,
                            'totalAmount': widget.totalAmount,
                            'pixKey': pixKey,
                          });
                        } catch (e) {
                          setState(() {
                            _isProcessing = false;
                          });
                          showErrorDialog('Erro ao processar venda: ${e.toString()}');
                        }
                      } else {
                        showErrorDialog('Chave PIX inválida. Verifique os dados informados.');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isProcessing || _pixKeyController.text.isEmpty
                    ? Colors.grey
                    : const Color(0xFFC29503),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE9EAEC)),
                      ),
                    )
                  : const Text(
                      'Finalizar Venda',
                      style: TextStyle(
                        color: Color(0xFFE9EAEC),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: _isProcessing ? null : () {
                context.pop();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFFC29503),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFFC29503),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelValueRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  bool _validatePixKey(String key) {
    if (key.isEmpty) return false;
    
    final emailRegex = RegExp(r"^[\w-.]+@[\w-]+\.[a-zA-Z]{2,}");
    if (emailRegex.hasMatch(key)) return true;
    
    final digitsOnly = key.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 11) return true;
    
    if (digitsOnly.length >= 10 && digitsOnly.length <= 13) return true;
    
    final randomKey = RegExp(r'^[a-zA-Z0-9_-]{8,64}$');
    if (randomKey.hasMatch(key)) return true;
    
    return false;
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