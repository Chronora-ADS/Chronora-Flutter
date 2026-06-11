import 'dart:convert';

import 'package:chronora/core/api/api_service.dart';
import 'package:chronora/core/services/service_deadline_controller.dart';
import 'package:chronora/widgets/notification_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    ApiService.setClientForTesting(null);
  });

  group('Funcionalidade: Notificacao de prazo do pedido', () {
    test('identifica notificacao que permite renovar ou cancelar pedido', () {
      final notification = NotificationEntry.fromJson({
        'id': 1,
        'message':
            'Prazo do pedido chegou. Renove o prazo ou cancele o pedido.',
        'notificationTime': '2026-06-01T08:00:00',
        'service': {
          'id': 10,
          'title': 'Aula de Java',
          'status': 'CRIADO',
          'deadline': '2026-06-01',
        },
      });

      expect(
          ServiceDeadlineController.canRespondToDeadline(notification), isTrue);
      expect(notification.service.deadline, DateTime(2026, 6, 1));
    });

    test('envia nova data de prazo para o backend', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-valido'});
      late Uri requestedUri;
      late Map<String, dynamic> payload;
      late String? authHeader;

      ApiService.setClientForTesting(
        MockClient((request) async {
          requestedUri = request.url;
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          authHeader = request.headers['Authorization'];

          return http.Response(
            jsonEncode({'id': 10, 'deadline': '2026-06-05'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final controller = ServiceDeadlineController();
      await controller.renewDeadline(
        serviceId: 10,
        deadline: DateTime(2026, 6, 5, 14, 30),
      );

      expect(requestedUri.path, '/service/renewDeadline/10');
      expect(payload, {'deadline': '2026-06-05'});
      expect(authHeader, 'Bearer token-valido');
    });

    test('envia cancelamento do pedido para o backend', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-valido'});
      late Uri requestedUri;
      late Map<String, dynamic> payload;

      ApiService.setClientForTesting(
        MockClient((request) async {
          requestedUri = request.url;
          payload = jsonDecode(request.body) as Map<String, dynamic>;

          return http.Response(
            jsonEncode({'id': 10, 'status': 'CANCELADO'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final controller = ServiceDeadlineController();
      await controller.cancelService(serviceId: 10);

      expect(requestedUri.path, '/service/cancelService/10');
      expect(payload, isEmpty);
    });

    test('retorna mensagem amigavel quando backend falha', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-valido'});
      ApiService.setClientForTesting(
        MockClient(
          (_) async => http.Response(
            jsonEncode({'message': 'Novo prazo deve ser uma data futura.'}),
            400,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      final controller = ServiceDeadlineController();

      expect(
        () => controller.renewDeadline(
          serviceId: 10,
          deadline: DateTime(2026, 6, 1),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Novo prazo deve ser uma data futura.'),
          ),
        ),
      );
    });
  });
}
