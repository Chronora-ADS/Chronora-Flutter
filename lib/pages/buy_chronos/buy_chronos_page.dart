import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/backgrounds/background_default_widget.dart';
import 'buy_chronos_controller.dart';

class BuyChronosPage extends StatefulWidget {
  const BuyChronosPage({Key? key}) : super(key: key);

  @override
  State<BuyChronosPage> createState() => _BuyChronosPageState();
}

class _BuyChronosPageState extends State<BuyChronosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BuyChronosController>(context, listen: false)
          .initializeInitialValues();
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

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.preto,
          title: Text(
            'Sucesso',
            style: TextStyle(color: AppColors.branco),
          ),
          content: Text(
            message,
            style: TextStyle(color: AppColors.branco),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      appBar: AppBar(
        backgroundColor: AppColors.amareloClaro,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.preto),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Comprar Chronos',
          style: TextStyle(
            color: AppColors.preto,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Consumer<BuyChronosController>(
            builder: (context, controller, child) {
              return Row(
                children: [
                  Image.asset('assets/img/Coin.png', width: 24, height: 24),
                  const SizedBox(width: 4),
                  Text(
                    '${controller.currentBalance}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.preto,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              );
            },
          ),
        ],
      ),
      body: BackgroundDefaultWidget(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Consumer<BuyChronosController>(
              builder: (context, controller, child) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.branco,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Título
                        Center(
                          child: Text(
                            'Comprar Chronos',
                            style: TextStyle(
                              color: AppColors.preto,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Saldo atual
                        Row(
                          children: [
                            Text(
                              'Chronos atuais:',
                              style: TextStyle(
                                color: AppColors.preto,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '🪙 ${controller.currentBalance}',
                              style: TextStyle(
                                color: AppColors.preto,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Campo de quantidade (preenchido branco)
                        TextField(
                          controller: controller.amountController,
                          onChanged: controller.updatePurchaseAmount,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: AppColors.preto),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.branco,
                            hintText: 'Quantidade de compra',
                            hintStyle: TextStyle(color: AppColors.textoPlaceholder),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.cinza.withValues(alpha: 0.12)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Resumo com borda amarela
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.amareloClaro, width: 2),
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.branco,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _labelValueRow('Subtotal', 'R\$ ${controller.subtotal.toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              _labelValueRow('Taxa (10%)', 'R\$ ${controller.taxAmount.toStringAsFixed(2)}'),
                              const SizedBox(height: 10),
                              Divider(color: AppColors.cinza),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total', style: TextStyle(color: AppColors.preto, fontWeight: FontWeight.bold)),
                                  Text('R\$ ${controller.totalAmount.toStringAsFixed(2)}', style: TextStyle(color: AppColors.amareloClaro, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Chronos pós-compra
                        Text(
                          'Chronos pós-compra: 🪙 ${controller.chronosAfterPurchase}',
                          style: TextStyle(color: AppColors.preto),
                        ),
                        const SizedBox(height: 14),

                        // Botões
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  controller.reset();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.amareloClaro, width: 2),
                                  backgroundColor: AppColors.branco,
                                ),
                                child: Text('Cancelar', style: TextStyle(color: AppColors.amareloClaro)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: controller.canProceed
                                    ? () {
                                        int amount = int.tryParse(controller.amountController.text) ?? 0;
                                        controller.purchaseChronos(
                                          amount: amount,
                                          onSuccess: () {
                                            showSuccessDialog('Compra realizada com sucesso!\nChronos adicionados: $amount');
                                          },
                                          onError: (err) {
                                            showErrorDialog(err);
                                          },
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: controller.canProceed ? AppColors.branco : Colors.grey[400],
                                  foregroundColor: controller.canProceed ? AppColors.preto : Colors.black54,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text('Finalizar compra', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _labelValueRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.cinza)),
        Text(value, style: TextStyle(color: AppColors.preto, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
