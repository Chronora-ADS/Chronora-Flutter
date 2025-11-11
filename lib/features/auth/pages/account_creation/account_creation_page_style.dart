import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AccountCreationPageStyle {
	static Color fundoCartao = AppColors.branco;
	static double borderRadius = 40;

	static TextStyle titulo = const TextStyle(
		fontSize: 24,
		fontWeight: FontWeight.bold,
		color: AppColors.preto,
	);

	static ButtonStyle outlinedAnexo = OutlinedButton.styleFrom(
		side: const BorderSide(color: AppColors.amareloUmPoucoEscuro, width: 3),
		padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
		shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
	);

	static TextStyle textoAnexo = const TextStyle(
		fontSize: 18,
		fontWeight: FontWeight.bold,
		color: AppColors.amareloUmPoucoEscuro,
	);

	static TextStyle nomeArquivo = const TextStyle(
		fontSize: 14,
		color: Colors.grey,
	);

	static ButtonStyle primario = ElevatedButton.styleFrom(
		backgroundColor: AppColors.amareloUmPoucoEscuro,
		padding: const EdgeInsets.symmetric(vertical: 12),
		shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
	);

	static ButtonStyle secundario = OutlinedButton.styleFrom(
		side: const BorderSide(color: AppColors.amareloUmPoucoEscuro, width: 3),
		padding: const EdgeInsets.symmetric(vertical: 12),
		shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
	);

	static TextStyle textoPrimario = const TextStyle(
		fontSize: 18,
		fontWeight: FontWeight.bold,
		color: AppColors.branco,
	);

	static TextStyle textoSecundario = const TextStyle(
		fontSize: 18,
		fontWeight: FontWeight.bold,
		color: AppColors.amareloUmPoucoEscuro,
	);
}