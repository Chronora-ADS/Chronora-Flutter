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
        body: Stack(
            children: [
                // Elementos de fundo
                Positioned(
                    left: 0,
                    top: 0,
                    child: Image.asset(
                    'assets/img/TriangleLeft.png',
                    width: MediaQuery.of(context).size.width * 0.6,
                    fit: BoxFit.cover,
                    ),
                ),

                if (showLogo)
                    Positioned(
                    left: MediaQuery.of(context).size.width * 0.05,
                    top: MediaQuery.of(context).size.height * 0.03,
                    child: Row(
                        children: [
                        Image.asset(
                            'assets/img/LogoBackgroundYellow.png',
                            width: MediaQuery.of(context).size.width * 0.035,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                            'Chronora',
                            style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.preto,
                            ),
                        ),
                        ],
                    ),
                    ),

                Positioned(
                    right: 0,
                    top: 0,
                    child: Image.asset(
                    'assets/img/BarDescending.png',
                    width: MediaQuery.of(context).size.width * 0.15,
                    fit: BoxFit.cover,
                    ),
                ),

                Positioned(
                    left: 0,
                    bottom: 0,
                    child: Image.asset(
                    'assets/img/BarAscending.png',
                    width: MediaQuery.of(context).size.width * 0.15,
                    fit: BoxFit.cover,
                    ),
                ),

                Positioned(
                    right: MediaQuery.of(context).size.width * 0.22,
                    top: MediaQuery.of(context).size.height * 0.3,
                    child: Image.asset(
                    'assets/img/Comb1.png',
                    width: MediaQuery.of(context).size.width * 0.15,
                    fit: BoxFit.cover,
                    ),
                ),

                Positioned(
                    left: MediaQuery.of(context).size.width * 0.27,
                    bottom: MediaQuery.of(context).size.height * 0.1,
                    child: Image.asset(
                    'assets/img/Comb2.png',
                    width: MediaQuery.of(context).size.width * 0.15,
                    fit: BoxFit.cover,
                    ),
                ),

                // Conteúdo principal
                child,
                ],
            ),
        );
    }
}
