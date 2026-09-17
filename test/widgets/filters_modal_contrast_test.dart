import 'package:chronora/core/constants/app_colors.dart';
import 'package:chronora/widgets/filters_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Filtro tem textos legiveis no tema ${brightness.name}',
        (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: FiltersModal(onApplyFilters: (_) {}),
        ),
      ));
      await tester.pumpAndSettle();

      void expectDarkText(String text) {
        final paragraphs = find.descendant(
          of: find.text(text),
          matching: find.byType(RichText),
        );
        expect(paragraphs, findsWidgets);
        for (final element in paragraphs.evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          expect(paragraph.text.style?.color, AppColors.preto,
              reason: text);
        }
      }

      for (final text in [
        'Filtros',
        'Qualquer',
        ServiceFilters.remoteModality,
        'Presencial',
        'Todas as avaliações',
        'Mais recentes',
      ]) {
        expectDarkText(text);
      }

      for (final field in tester.widgetList<TextField>(find.byType(TextField))) {
        expect(field.style?.color, AppColors.preto);
        expect(field.decoration?.hintStyle?.color, AppColors.textoPlaceholder);
      }

      await tester.tap(find.text('Todas as avaliações').first);
      await tester.pumpAndSettle();
      expectDarkText('4 - 5 estrelas');
      await tester.tap(find.text('4 - 5 estrelas').last);
      await tester.pumpAndSettle();
      expectDarkText('4 - 5 estrelas');

      await tester.ensureVisible(find.text('Mais recentes').first);
      await tester.tap(find.text('Mais recentes').first);
      await tester.pumpAndSettle();
      expectDarkText('Mais antigos');
      await tester.tap(find.text('Mais antigos').last);
      await tester.pumpAndSettle();
      expectDarkText('Mais antigos');
    });
  }
}
