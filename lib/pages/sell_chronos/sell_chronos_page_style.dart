import 'package:flutter/material.dart';

class SellChronosPageStyle {
  static const Color darkBg = Color(0xFF0B0C0C);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color accentYellow = Color(0xFFFFC300);
  static const Color textPrimary = Color(0xFFE9EAEC);
  static const Color textSecondary = Color(0xFFB5BFAE);
  static const Color borderGray = Color(0xFF2A2A2A);
  static const Color errorRed = Color(0xFFFF6B6B);

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
          color: textSecondary.withOpacity(0.6),
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

  static const TextStyle headerTitle = TextStyle(
    color: textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontFamily: 'Roboto',
  );

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

  static ButtonStyle sellButtonStyle({required bool enabled}) =>
      ElevatedButton.styleFrom(
        backgroundColor: enabled ? accentYellow : accentYellow.withOpacity(0.3),
        foregroundColor: enabled ? darkBg : textSecondary.withOpacity(0.5),
        elevation: enabled ? 4 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );

  static const TextStyle errorText = TextStyle(
    color: errorRed,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: 'Roboto',
  );

  static const double paddingMedium = 16.0;
  static const double gapSmall = 8.0;
  static const double gapMedium = 12.0;
  static const double gapLarge = 16.0;
}
