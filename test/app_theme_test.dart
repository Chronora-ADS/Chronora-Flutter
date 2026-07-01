import 'package:chronora/core/constants/app_colors.dart';
import 'package:chronora/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Cenario: Dado app carregado, entao scrollbar global e branco',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ChronoraFlutter());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final darkThumbColor =
        app.darkTheme?.scrollbarTheme.thumbColor?.resolve(<WidgetState>{});
    final lightThumbColor =
        app.theme?.scrollbarTheme.thumbColor?.resolve(<WidgetState>{});

    expect(darkThumbColor, AppColors.branco);
    expect(lightThumbColor, AppColors.preto);
  });
}
