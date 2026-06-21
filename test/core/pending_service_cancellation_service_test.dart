import 'package:chronora/core/services/pending_service_cancellation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Funcionalidade: pendencias de justificativa de cancelamento', () {
    test('persiste pendencia ate a justificativa ser registrada', () async {
      SharedPreferences.setMockInitialValues({});

      await PendingServiceCancellationStore.upsert(
        PendingServiceCancellationJustification(
          serviceId: 15,
          serviceTitle: 'Declaracao anual de MEI',
          requesterName: 'Ana Cliente',
          createdAt: DateTime(2026, 6, 15, 10),
        ),
      );

      final pending = await PendingServiceCancellationStore.getAll();

      expect(pending, hasLength(1));
      expect(pending.first.serviceId, 15);
      expect(pending.first.displayTitle, 'Declaracao anual de MEI');
      expect(pending.first.displayRequesterName, 'Ana Cliente');
      expect(await PendingServiceCancellationStore.hasPending(), isTrue);
    });

    test('remove pendencia somente pelo id do servico resolvido', () async {
      SharedPreferences.setMockInitialValues({});

      await PendingServiceCancellationStore.upsert(
        PendingServiceCancellationJustification(
          serviceId: 10,
          serviceTitle: 'Pedido antigo',
          requesterName: 'Cliente A',
          createdAt: DateTime(2026, 6, 15, 9),
        ),
      );
      await PendingServiceCancellationStore.upsert(
        PendingServiceCancellationJustification(
          serviceId: 11,
          serviceTitle: 'Pedido novo',
          requesterName: 'Cliente B',
          createdAt: DateTime(2026, 6, 15, 10),
        ),
      );

      await PendingServiceCancellationStore.remove(10);

      final pending = await PendingServiceCancellationStore.getAll();
      expect(pending, hasLength(1));
      expect(pending.first.serviceId, 11);
    });
  });
}
