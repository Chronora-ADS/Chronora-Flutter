import 'package:chronora/core/services/pending_service_cancellation_service.dart';
import 'package:chronora/widgets/auth_guard.dart';
import 'package:chronora/widgets/pending_service_cancellation_obligations.dart';
import 'package:chronora/widgets/service_cancellation_reason_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Funcionalidade: obrigatoriedade de justificativa pendente', () {
    testWidgets('mostra aba inferior em rota protegida quando ha pendencia',
        (tester) async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-valido'});
      await _addPending();

      await tester.pumpWidget(
        const MaterialApp(
          home: AuthGuard(
            child: Scaffold(body: Text('Conteudo privado')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Conteudo privado'), findsOneWidget);
      expect(
        find.text('Voce possui 1 pendencia obrigatoria.'),
        findsOneWidget,
      );
      expect(find.text('Ver pendencias'), findsOneWidget);
    });

    testWidgets('bloqueia rota sensivel enquanto pendencia estiver aberta',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _addPending();

      await tester.pumpWidget(
        const MaterialApp(
          home: PendingActionGate(
            actionLabel: 'criar pedido',
            child: Text('Formulario liberado'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Formulario liberado'), findsNothing);
      expect(find.text('Antes de criar pedido'), findsOneWidget);
      expect(find.text('Ver pendencias'), findsOneWidget);
    });

    testWidgets('modal de justificativa exibe pedido e cliente',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceCancellationReasonModal(
              serviceTitle: 'Declaracao anual de MEI',
              requesterName: 'Ana Cliente',
            ),
          ),
        ),
      );

      expect(find.text('Pedido'), findsOneWidget);
      expect(find.text('Declaracao anual de MEI'), findsOneWidget);
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Ana Cliente'), findsOneWidget);
    });
  });
}

Future<void> _addPending() {
  return PendingServiceCancellationStore.upsert(
    PendingServiceCancellationJustification(
      serviceId: 15,
      serviceTitle: 'Declaracao anual de MEI',
      requesterName: 'Ana Cliente',
      createdAt: DateTime(2026, 6, 15, 10),
    ),
  );
}
