import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/header.dart';
import '../../../widgets/side_menu.dart';
import '../../../widgets/wallet_modal.dart';
import '../../../core/router/auth_wrapper.dart';
import '../../../core/constants/app_routes.dart';

class BuySuccessPage extends StatefulWidget {
  final int chronosAmount;
  final double totalAmount;
  final String paymentMethod;

  const BuySuccessPage({
    super.key,
    required this.chronosAmount,
    required this.totalAmount,
    required this.paymentMethod,
  });

  @override
  State<BuySuccessPage> createState() => _BuySuccessPageState();
}

class _BuySuccessPageState extends State<BuySuccessPage> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFFC29503),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  Widget _buildSuccessContent() {
    const double chronosPrice = 2.50;
    const double taxPercentage = 0.10;
    
    final subtotal = widget.chronosAmount * chronosPrice;
    final taxa = subtotal * taxPercentage;
    final total = subtotal + taxa;
    
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAEC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 40,
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Compra realizada com sucesso!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC29503), width: 2),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF8F9FA),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  'Chronos comprados:',
                  '${widget.chronosAmount}',
                  Icons.schedule,
                ),
                const SizedBox(height: 16),
                
                _buildDetailRow(
                  'Preço por Chronos:',
                  'R\$ ${chronosPrice.toStringAsFixed(2)}',
                  Icons.monetization_on,
                ),
                const SizedBox(height: 16),
                
                _buildDetailRow(
                  'Subtotal:',
                  'R\$ ${subtotal.toStringAsFixed(2)}',
                  Icons.calculate,
                ),
                const SizedBox(height: 16),
                
                _buildDetailRow(
                  'Taxa (10%):',
                  'R\$ ${taxa.toStringAsFixed(2)}',
                  Icons.percent,
                ),
                const SizedBox(height: 16),
                
                _buildDetailRow(
                  'Total pago:',
                  'R\$ ${total.toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
                const SizedBox(height: 16),
                
                _buildDetailRow(
                  'Método de pagamento:',
                  widget.paymentMethod,
                  Icons.payment,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          Text(
            'Os Chronos foram creditados instantaneamente em sua conta.',
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          // Botão Voltar ao Início - CORRIGIDO
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Navega para a tela principal
                context.go(AppRoutes.main);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC29503),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Voltar ao Início',
                style: TextStyle(
                  color: Color(0xFFE9EAEC),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botão Nova Compra - CORRIGIDO
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                // CORREÇÃO: Usando go_router corretamente
                // 1. Volta para a tela principal
                context.go(AppRoutes.main);
                // 2. Depois navega para buy-chronos
                Future.delayed(const Duration(milliseconds: 100), () {
                  context.pushNamed('buy-chronos');
                });
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
                'Fazer Nova Compra',
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
                      child: _buildSuccessContent(),
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