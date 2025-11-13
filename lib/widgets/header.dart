import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class Header extends StatelessWidget implements PreferredSizeWidget {
  final int coinCount;
  final VoidCallback? onMenuPressed;

  const Header({
    super.key,
    this.coinCount = 123,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.amareloClaro,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: AppColors.preto),
        onPressed: onMenuPressed,
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
        Row(
          children: [
            Image.asset('assets/img/Coin.png', width: 24, height: 24),
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
      elevation: 0, // Remove sombra
    );
  }
}