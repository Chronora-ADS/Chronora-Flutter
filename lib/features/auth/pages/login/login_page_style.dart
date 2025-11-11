import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class LoginPageStyle {
	static Color fundoCartao = AppColors.branco;
	static double borderRadius = 40;

	static TextStyle titulo = const TextStyle(
		fontSize: 24,
		fontWeight: FontWeight.bold,
		color: AppColors.preto,
	);

	static ButtonStyle primario = ElevatedButton.styleFrom(
		backgroundColor: AppColors.amareloUmPoucoEscuro,
		padding: const EdgeInsets.symmetric(vertical: 8),
		shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
	);

	static ButtonStyle secundario = OutlinedButton.styleFrom(
		side: const BorderSide(color: AppColors.amareloUmPoucoEscuro, width: 3),
		padding: const EdgeInsets.symmetric(vertical: 8),
		shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
	);

	static TextStyle textoPrimario = const TextStyle(
		fontSize: 22,
		fontWeight: FontWeight.bold,
		color: AppColors.branco,
	);

	static TextStyle textoSecundario = const TextStyle(
		fontSize: 22,
		fontWeight: FontWeight.bold,
		color: AppColors.amareloUmPoucoEscuro,
	);

	static TextStyle lembrete = const TextStyle(
		color: AppColors.preto,
		fontSize: 14,
	);

	static TextStyle esqueci = const TextStyle(
		color: AppColors.azul,
		fontStyle: FontStyle.italic,
		fontSize: 14,
	);
}