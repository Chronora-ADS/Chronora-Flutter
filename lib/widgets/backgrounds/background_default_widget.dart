import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class BackgroundWidget extends StatelessWidget {
  final Widget child;
  final bool showLogo;

  const BackgroundWidget(
      {super.key, required this.child, this.showLogo = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Barra ascendente (inferior esquerda)
              Positioned(
                left: 0,
                top: 900,
                child: Image.asset(
                  'assets/img/Comb2.png',
                  width: constraints.maxWidth * 0.3,
                  fit: BoxFit.cover,
                ),
              ),

              // Comb1 (superior direita) - CORRIGIDO: garantindo que não ultrapasse a tela
              Positioned(
                right: 0,
                top: 350,
                child: Image.asset(
                  'assets/img/Comb4.png',
                  width: constraints.maxWidth * 0.3,
                  fit: BoxFit.contain, // Mudado para contain para não distorcer
                ),
              ),

              // Conteúdo principal
              child,
            ],
          );
        },
      ),
    );
  }

  double _getResponsiveFontSize(BoxConstraints constraints) {
    final double width = constraints.maxWidth;

    if (width < 350) return 16;
    if (width < 400) return 18;
    return 20;
  }
}
