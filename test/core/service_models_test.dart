import 'dart:convert';

import 'package:chronora/core/models/main_page_requests_model.dart';
import 'package:chronora/core/models/create_request_model.dart';
import 'package:chronora/core/models/service_detail_model.dart';
import 'package:chronora/core/models/service_tracking_type.dart';
import 'package:chronora/core/utils/service_image_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Funcionalidade: Meus pedidos e imagens de servico', () {
    test('parseia status, usuario aceito, rating e categorias flexiveis', () {
      final service = Service.fromJson({
        'id': '42',
        'title': 'Aula de violao',
        'description': 'Aula introdutoria para iniciantes',
        'serviceImageUrl': '/uploads/aula.png',
        'timeChronos': '3',
        'status': 'ACEITO',
        'userCreator': {
          'id': 7,
          'name': 'Ana',
          'email': 'ana@example.com',
          'rating': '4,5',
        },
        'userAccepted': {
          'id': '9',
          'name': 'Bruno',
          'email': 'bruno@example.com',
          'rating': 4.2,
        },
        'categories': [
          'Musica',
          {'name': 'Ensino'},
        ],
        'deadline': '2026-05-30',
        'modality': 'REMOTO',
        'trackingType': 'CUSTOM',
        'trackingDescription': 'Por modulo concluido',
      });

      expect(service.id, 42);
      expect(service.serviceImageUrl, '/uploads/aula.png');
      expect(service.status, 'ACEITO');
      expect(service.userAccepted?.id, 9);
      expect(service.userAccepted?.rating, 4.2);
      expect(service.userCreator.rating, 4.5);
      expect(service.trackingType, ServiceTrackingType.custom);
      expect(service.trackingDescription, 'Por modulo concluido');
      expect(service.categoryEntities.map((category) => category.name), [
        'Musica',
        'Ensino',
      ]);
    });

    test('identifica somente pedidos com status criado', () {
      Service serviceWithStatus(String status) {
        return Service.fromJson({
          'id': 1,
          'title': 'Aula de ingles',
          'description': 'Conversacao para iniciantes',
          'timeChronos': 2,
          'status': status,
          'userCreator': {'name': 'Ana'},
        });
      }

      expect(serviceWithStatus('CRIADO').isCreated, isTrue);
      expect(serviceWithStatus(' criado ').isCreated, isTrue);
      expect(serviceWithStatus('ACEITO').isCreated, isFalse);
      expect(serviceWithStatus('CONCLUIDO').isCreated, isFalse);
      expect(serviceWithStatus('CANCELADO').isCreated, isFalse);
    });

    test(
      'resolve imagem em data URI, URL absoluta e caminho relativo da API',
      () {
        final bytes = utf8.encode('imagem fake');
        final dataUri = 'data:image/png;base64,${base64Encode(bytes)}';

        expect(ServiceImageResolver.tryDecodeBytes(dataUri), bytes);
        expect(
          ServiceImageResolver.resolveNetworkUrl(
            'https://cdn.example.com/a.png',
          ),
          'https://cdn.example.com/a.png',
        );
        expect(
          ServiceImageResolver.resolveNetworkUrl('/uploads/a.png'),
          'http://localhost:8085/uploads/a.png',
        );
      },
    );

    test('parseia contador da chamada de codigo no detalhe do servico', () {
      final service = ServiceDetailModel.fromJson({
        'id': 42,
        'title': 'Aula de violao',
        'description': 'Aula introdutoria',
        'timeChronos': 3,
        'deadline': '2026-05-30',
        'modality': 'REMOTO',
        'status': 'ACEITO',
        'postedAt': '2026-05-29T10:00:00',
        'verificationCodeCallCount': 2,
        'userCreator': {
          'id': 7,
          'name': 'Ana',
          'phoneNumber': 47999999999,
          'rating': 3.8,
        },
        'userAccepted': {
          'id': 9,
          'name': 'Bruno',
          'phoneNumber': 47988888888,
          'rating': '4,7',
        },
        'verificationCode': '1234',
        'verificationCodeExpiresAt': '2026-05-29T10:02:00',
        'trackingType': 'COMPLETION',
      });

      expect(service.verificationCodeCallCount, 2);
      expect(service.userCreator.rating, 3.8);
      expect(service.acceptedRequestInfo?.authenticationCode, '1234');
      expect(service.acceptedRequestInfo?.acceptedUser?.name, 'Bruno');
      expect(service.acceptedRequestInfo?.acceptedUser?.rating, 4.7);
      expect(service.trackingType, ServiceTrackingType.completion);
    });

    test('serializa metrica customizada na criacao do pedido', () {
      final request = CreateRequestModel(
        title: 'Pintura de sala',
        description: 'Pintura completa da sala com acabamento uniforme.',
        timeChronos: 8,
        deadline: '2026-07-10',
        categories: const ['Pintura'],
        modality: 'PRESENCIAL',
        trackingType: ServiceTrackingType.custom,
        trackingDescription: ' Por metro quadrado pintado ',
      );

      final json = request.toJson();

      expect(json['trackingType'], 'CUSTOM');
      expect(json['trackingDescription'], 'Por metro quadrado pintado');
    });

    test('serializa marco de tempo na criacao do pedido', () {
      final request = CreateRequestModel(
        title: 'Aula de ingles',
        description: 'Aulas semanais com acompanhamento de progresso.',
        timeChronos: 10,
        deadline: '2026-07-10',
        categories: const ['Educacao'],
        modality: 'REMOTO',
        trackingType: ServiceTrackingType.time,
        trackingDescription: ' 10% por hora ',
      );

      final json = request.toJson();

      expect(json['trackingType'], 'TIME');
      expect(json['trackingDescription'], '10% por hora');
    });

    test('parseia rating de usuario aceito em payload plano', () {
      final service = ServiceDetailModel.fromJson({
        'id': 42,
        'title': 'Aula de violao',
        'description': 'Aula introdutoria',
        'timeChronos': 3,
        'deadline': '2026-05-30',
        'modality': 'REMOTO',
        'status': 'ACEITO',
        'userCreator': {'id': 7, 'name': 'Ana'},
        'acceptedUserId': 9,
        'acceptedUserName': 'Bruno',
        'acceptedUserPhone': 47988888888,
        'acceptedUserRating': '4,6',
      });

      expect(service.acceptedRequestInfo?.acceptedUser?.id, 9);
      expect(service.acceptedRequestInfo?.acceptedUser?.name, 'Bruno');
      expect(service.acceptedRequestInfo?.acceptedUser?.rating, 4.6);
    });
  });
}
