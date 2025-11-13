import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final int coinCount;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onCoinPressed;

  const Header({
    super.key,
    this.coinCount = 0,
    this.onMenuPressed,
    this.onCoinPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.amareloClaro,
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: AppColors.preto),
            onPressed: onMenuPressed ?? () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/img/LogoBackgroundYellow.png',
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 8),
          const Text(
            'Chronora',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.preto,
            ),
          ),
        ],
      ),
      actions: [
        // Moedas SEM círculo branco
        Row(
          children: [
            GestureDetector(
              onTap: onCoinPressed,
              child: Image.asset('assets/img/Coin.png', width: 24, height: 24),
            ),
            const SizedBox(width: 4),
            Text(
              coinCount.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ],
    );
  }
}