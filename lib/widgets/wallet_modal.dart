import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/chronos_wallet_service.dart';
import 'pending_service_cancellation_obligations.dart';

class WalletModal extends StatefulWidget {
  final VoidCallback onClose;

  const WalletModal({super.key, required this.onClose});

  @override
  State<WalletModal> createState() => _WalletModalState();
}

class _WalletModalState extends State<WalletModal> {
  int _balance = 0;
  int _inActiveServices = 0;
  bool _isLoading = true;

  final _service = ChronosWalletService();

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final summary = await _service.fetchWalletSummary();
      if (!mounted) return;
      setState(() {
        _balance = summary.balance;
        _inActiveServices = summary.chronosInActiveServices;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              const Center(
                child: Text(
                  'Carteira',
                  style: TextStyle(
                    fontSize: 24,
                    color: AppColors.preto,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: widget.onClose,
                  icon: const ImageIcon(
                    AssetImage('assets/img/Close.png'),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.preto),
                ),
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _balance.toString(),
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset('assets/img/Coin.png', width: 32, height: 32),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Na carteira', _balance),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Em pedidos', _inActiveServices),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.amareloUmPoucoEscuro,
            ),
            child: InkWell(
              onTap: () async {
                final canContinue = await PendingServiceCancellationObligations
                    .ensureCanContinue(
                  context,
                  actionLabel: 'comprar Chronos',
                );
                if (!canContinue || !context.mounted) return;
                widget.onClose();
                Navigator.pushNamed(context, AppRoutes.buyChronos);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Text(
                    'Comprar Chronos',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.branco,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.amareloUmPoucoEscuro, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: InkWell(
              onTap: () {
                widget.onClose();
                Navigator.pushNamed(context, AppRoutes.sellChronos);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                child: const Center(
                  child: Text(
                    'Vender Chronos',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.amareloUmPoucoEscuro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.preto,
          ),
        ),
        Row(
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
            const SizedBox(width: 4),
            Image.asset('assets/img/Coin.png', width: 16, height: 16),
          ],
        ),
      ],
    );
  }
}
