import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MainPageStyle {
	static const Color fundo = Color(0xFF0B0C0C);
	static const Color appBarFundo = AppColors.amareloClaro;

	static const TextStyle tituloAppBar = TextStyle(
		fontSize: 20,
		fontWeight: FontWeight.bold,
		color: AppColors.preto,
	);

	static const TextStyle textoSection = TextStyle(
		color: AppColors.branco,
		fontSize: 16,
	);

	static BoxDecoration cardSection = BoxDecoration(
		color: AppColors.amareloClaro.withOpacity(0.1),
		borderRadius: BorderRadius.circular(12),
		border: Border.all(color: AppColors.amareloClaro),
	);

	static InputDecoration searchDecoration({String? hint}) => InputDecoration(
		hintText: hint ?? 'Pesquisar...',
		hintStyle: const TextStyle(color: AppColors.textoPlaceholder),
		filled: true,
		fillColor: AppColors.branco,
		border: OutlineInputBorder(
			borderRadius: BorderRadius.circular(20),
			borderSide: BorderSide.none,
		),
		contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
		prefixIcon: const Icon(Icons.search, color: AppColors.textoPlaceholder),
	);
}