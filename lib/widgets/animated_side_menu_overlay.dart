import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import 'side_menu.dart';

class AnimatedSideMenuOverlay extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onWalletPressed;
  final String? userName;
  final double? userRating;
  final String? userPhotoUrl;
  final double top;

  const AnimatedSideMenuOverlay({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onWalletPressed,
    this.userName,
    this.userRating,
    this.userPhotoUrl,
    this.top = kToolbarHeight * 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final menuWidth = MediaQuery.of(context).size.width * 0.6;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !isOpen,
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: isOpen ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  color: AppColors.preto.withValues(alpha: 0.5),
                ),
              ),
            ),
            AnimatedSlide(
              offset: isOpen ? Offset.zero : const Offset(-1, 0),
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: menuWidth,
                child: SideMenu(
                  onWalletPressed: onWalletPressed,
                  userName: userName,
                  userRating: userRating,
                  userPhotoUrl: userPhotoUrl,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
