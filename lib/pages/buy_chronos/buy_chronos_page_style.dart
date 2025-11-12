import 'package:flutter/material.dart';

/// Estilos e tema da tela de compra de Chronos
/// 
/// Implementa tema escuro moderno com amarelo dourado vibrante
class BuyChronosPageStyle {
  // Cores do tema
  static const Color darkBg = Color(0xFF0B0C0C); // Preto profundo
  static const Color darkCard = Color(0xFF1A1A1A); // Cinza muito escuro
  static const Color accentYellow = Color(0xFFFFC300); // Amarelo vibrante
  static const Color lightYellow = Color(0xFFFFC300); // Amarelo claro (accent)
  static const Color textPrimary = Color(0xFFE9EAEC); // Branco off
  static const Color textSecondary = Color(0xFFB5BFAE); // Cinza
  static const Color borderGray = Color(0xFF2A2A2A); // Borda cinza
  static const Color errorRed = Color(0xFFFF6B6B); // Vermelho erro
  static const Color successGreen = Color(0xFF51CF66); // Verde sucesso

  // Padrão de hexágonos translúcidos (via Container com BoxDecoration)
  static const String hexagonPattern = 'assets/patterns/hexagon-pattern.svg';

  // ========== HEADER STYLES ==========
  static BoxDecoration headerDecoration() => BoxDecoration(
    color: darkCard,
    border: Border(
      bottom: BorderSide(color: borderGray, width: 1),
    ),
  );

  static const TextStyle headerTitle = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'Roboto',
  );

  static const TextStyle headerChronos = TextStyle(
    color: accentYellow,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Roboto',
  );

  // ========== SEARCH BAR STYLES ==========
  static InputDecoration searchBarDecoration() => InputDecoration(
    hintText: 'Pintura de parede, aula de inglês...',
    hintStyle: TextStyle(
      color: textSecondary.withOpacity(0.6),
      fontSize: 14,
    ),
    prefixIcon: Icon(
      Icons.search,
      color: accentYellow.withOpacity(0.7),
    ),
    filled: true,
    fillColor: borderGray.withOpacity(0.3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderGray, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderGray, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: accentYellow, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  // ========== CARD STYLES ==========
  static BoxDecoration cardDecoration() => BoxDecoration(
    color: darkCard,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: borderGray, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration calculationSectionDecoration() => BoxDecoration(
    color: darkBg,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: accentYellow, width: 1.5),
  );

  // ========== INPUT FIELD STYLES ==========
  static InputDecoration inputDecoration({
    required String label,
    required String hint,
    bool hasError = false,
  }) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: accentYellow,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: textSecondary.withOpacity(0.5),
          fontSize: 14,
        ),
        filled: true,
        fillColor: borderGray.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? errorRed : borderGray,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: hasError ? errorRed : borderGray,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: accentYellow,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  // ========== CALCULATION TEXT STYLES ==========
  static const TextStyle calculationLabel = TextStyle(
    color: textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
  );

  static const TextStyle calculationValue = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Roboto',
  );

  static const TextStyle calculationTax = TextStyle(
    color: accentYellow,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Roboto',
  );

  static const TextStyle calculationTotal = TextStyle(
    color: accentYellow,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    fontFamily: 'Roboto',
  );

  static const TextStyle chronosBalance = TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
  );

  // ========== BUTTON STYLES ==========
  static ButtonStyle cancelButtonStyle() => ElevatedButton.styleFrom(
    backgroundColor: borderGray.withOpacity(0.5),
    foregroundColor: textPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: borderGray, width: 1),
    ),
  );

  static ButtonStyle purchaseButtonStyle({required bool enabled}) =>
      ElevatedButton.styleFrom(
        backgroundColor: enabled ? accentYellow : accentYellow.withOpacity(0.3),
        foregroundColor: enabled ? darkBg : textSecondary.withOpacity(0.5),
        elevation: enabled ? 4 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );

  // ========== ERROR STYLES ==========
  static const TextStyle errorText = TextStyle(
    color: errorRed,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
  );

  // ========== TOOLTIP STYLES ==========
  static const TextStyle tooltipText = TextStyle(
    color: darkBg,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
    height: 1.4,
  );

  // ========== SPACING & LAYOUT ==========
  static const double paddingXs = 8.0;
  static const double paddingSmall = 12.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXl = 32.0;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  static const double gapSmall = 8.0;
  static const double gapMedium = 12.0;
  static const double gapLarge = 16.0;
  static const double gapXl = 24.0;
}
