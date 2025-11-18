import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class WalletModal extends StatelessWidget {
  final VoidCallback onClose;

  const WalletModal({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
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
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.preto,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '299',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/img/Coin.png',
                  width: 32,
                  height: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.amareloUmPoucoEscuro,
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                onClose();
                Navigator.pushNamed(context, '/buy-chronos');
              },
              borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.branco,
              border: Border.all(
                color: AppColors.amareloUmPoucoEscuro,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                onClose();
                Navigator.pushNamed(context, '/sell-chronos');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Center(
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
}
