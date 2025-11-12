import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BackgroundAuthWidget extends StatelessWidget {
	final Widget child;
	final bool showLogo;

	const BackgroundAuthWidget({
		super.key, 
		required this.child, 
		this.showLogo = true
	});

	@override
	Widget build(BuildContext context) {
		final screenSize = MediaQuery.of(context).size;
		final isMobile = screenSize.width < 600;
		final isTablet = screenSize.width < 1200;

		return Scaffold(
			backgroundColor: AppColors.preto,
			body: Stack(
				children: [
					// Triângulo da esquerda - RESPONSIVO
					Positioned(
						left: 0,
						top: 0,
						child: SizedBox(
							width: _getElementWidth(screenSize.width, 0.8, 0.6),
							child: Stack(
								children: [
									Image.asset(
										'assets/img/TriangleLeft.png',
										width: _getElementWidth(screenSize.width, 0.8, 0.6),
										fit: BoxFit.cover,
									),

									// Logo RESPONSIVA
									if (showLogo)
										Positioned(
											left: _getResponsiveValue(screenSize.width, 20, 50),
											top: _getResponsiveValue(screenSize.height, 20, 80),
											child: Container(
												constraints: BoxConstraints(
													maxWidth: _getElementWidth(screenSize.width, 0.6, 0.4),
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
															height: _getResponsiveValue(screenSize.height, 30, 60),
														),
														const SizedBox(width: 8),
														Flexible(
															child: Text(
																'Chronora',
																style: TextStyle(
																	fontSize: _getResponsiveFontSize(screenSize.width),
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

					// Barra ascendente (inferior esquerda) - RESPONSIVA
					Positioned(
						left: 0,
						bottom: 0,
						child: Image.asset(
							'assets/img/BarAscending.png',
							width: _getElementWidth(screenSize.width, 0.4, 0.3),
							fit: BoxFit.cover,
						),
					),

					// Comb1 (superior direita) - RESPONSIVA
					Positioned(
						right: 0,
						top: _getResponsiveValue(screenSize.height, 0, 100),
						child: Image.asset(
							'assets/img/Comb1.png',
							width: _getElementWidth(screenSize.width, 0.3, 0.2),
							fit: BoxFit.contain,
						),
					),

					// Conteúdo principal
					child,
				],
			),
		);
	}

	// Calcula largura responsiva considerando máximo - CORRIGIDO
	double _getElementWidth(double screenWidth, double mobilePercent, double desktopPercent) {
		final percent = screenWidth < 600 ? mobilePercent : desktopPercent;
		final maxWidth = screenWidth < 600 ? double.infinity : 800;
		return (screenWidth * percent).clamp(0, maxWidth).toDouble();
	}

	// Valor responsivo com limites
	double _getResponsiveValue(double screenSize, double mobileValue, double desktopValue) {
		if (screenSize < 600) {
			return mobileValue;
		} else if (screenSize < 1200) {
			return (mobileValue + desktopValue) / 2;
		}
		return desktopValue;
	}

	// Tamanho de fonte responsivo
	double _getResponsiveFontSize(double screenWidth) {
		if (screenWidth < 350) return 16;
		if (screenWidth < 400) return 18;
		if (screenWidth < 600) return 20;
		if (screenWidth < 900) return 24;
		if (screenWidth < 1200) return 28;
		return 32; // Web muito grande
	}
}