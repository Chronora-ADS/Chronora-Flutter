import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/header.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';
import 'sell_chronos_controller.dart';
import 'pix_sell_page.dart';

class SellChronosPage extends StatefulWidget {
  const SellChronosPage({Key? key}) : super(key: key);

  @override
  State<SellChronosPage> createState() => _SellChronosPageState();
}

class _SellChronosPageState extends State<SellChronosPage> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SellChronosController>(context, listen: false)
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

  Widget _buildForm(BuildContext context, SellChronosController controller) {
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
                    child: Consumer<SellChronosController>(
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
    );
  }
}