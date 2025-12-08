import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BackgroundDefaultWidget extends StatelessWidget {
	final Widget child;
	final bool showLogo;

	const BackgroundDefaultWidget({
		super.key, 
		required this.child, 
		this.showLogo = true
	});

	@override
	Widget build(BuildContext context) {
		final screenSize = MediaQuery.of(context).size;

		return Scaffold(
			backgroundColor: AppColors.preto,
			body: Stack(
				children: [
					// Comb2 - POSIÇÃO RESPONSIVA
					Positioned(
						left: 0,
						top: _getResponsiveTop(screenSize.height, 900, 200),
						child: Image.asset(
							'assets/img/Comb2.png',
							width: _getElementWidth(screenSize.width, 0.3, 0.15),
							fit: BoxFit.cover,
						),
					),

					// Comb4 - POSIÇÃO RESPONSIVA
					Positioned(
						right: 0,
						top: _getResponsiveTop(screenSize.height, 350, 150),
						child: Image.asset(
							'assets/img/Comb4.png',
							width: _getElementWidth(screenSize.width, 0.3, 0.15),
							fit: BoxFit.contain,
						),
					),

					// Conteúdo principal
					child,
				],
			),
		);
	}

	double _getElementWidth(double screenWidth, double mobilePercent, double desktopPercent) {
		final percent = screenWidth < 600 ? mobilePercent : desktopPercent;
		final maxWidth = screenWidth < 600 ? double.infinity : 400;
		return (screenWidth * percent).clamp(0, maxWidth).toDouble();
	}

	double _getResponsiveTop(double screenHeight, double mobileTop, double desktopTop) {
		if (screenHeight < 800) return mobileTop * 0.7;
		if (screenHeight < 1200) return mobileTop;
		return desktopTop;
	}
}