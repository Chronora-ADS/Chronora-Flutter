import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BackgroundWidget extends StatelessWidget {
  final Widget child;
  final bool showLogo;

  const BackgroundWidget({super.key, required this.child, this.showLogo = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Triângulo da esquerda
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: constraints.maxWidth * 0.8,
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/img/TriangleLeft.png',
                        width: constraints.maxWidth * 0.8,
                        fit: BoxFit.cover,
                      ),
                      
                      // Logo POSICIONADA DENTRO DO TRIÂNGULO
                      if (showLogo)
                        Positioned(
                          left: constraints.maxWidth * 0.05,
                          top: constraints.maxHeight * 0.03,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.6, // Limita a largura máxima
                            ),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/img/LogoBackgroundYellow.png',
                                  height: constraints.maxHeight * 0.05,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    'Chronora',
                                    style: TextStyle(
                                      fontSize: _getResponsiveFontSize(constraints),
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.preto,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Barra ascendente (inferior esquerda)
              Positioned(
                left: 0,
                bottom: 0,
                child: Image.asset(
                  'assets/img/BarAscending.png',
                  width: constraints.maxWidth * 0.4,
                  fit: BoxFit.cover,
                ),
              ),

              // Comb1 (superior direita) - CORRIGIDO: garantindo que não ultrapasse a tela
              Positioned(
                right: 0,
                top: 0,
                child: Image.asset(
                  'assets/img/Comb1.png',
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