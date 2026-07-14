import 'package:chronora/core/models/service_tracking_type.dart';
import 'package:chronora/widgets/progress_tracking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe a metrica customizada e sua descricao', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProgressTrackingCard(
            trackingType: ServiceTrackingType.custom,
            trackingDescription: 'Por metro quadrado pintado',
          ),
        ),
      ),
    );

    expect(find.text('Métrica de Progresso'), findsOneWidget);
    expect(find.text('Campos customizados'), findsOneWidget);
    expect(find.text('Por metro quadrado pintado'), findsOneWidget);
  });
}
