import 'dart:convert';

import 'package:chronora/core/models/main_page_requests_model.dart';
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
        },
        'categories': [
          'Musica',
          {'name': 'Ensino'}
        ],
        'deadline': '2026-05-30',
        'modality': 'REMOTO',
      });

      expect(service.id, 42);
      expect(service.serviceImageUrl, '/uploads/aula.png');
      expect(service.status, 'ACEITO');
      expect(service.userAccepted?.id, 9);
      expect(service.userCreator.rating, 4.5);
      expect(
        service.categoryEntities.map((category) => category.name),
        ['Musica', 'Ensino'],
      );
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

    test('resolve imagem em data URI, URL absoluta e caminho relativo da API',
        () {
      final bytes = utf8.encode('imagem fake');
      final dataUri = 'data:image/png;base64,${base64Encode(bytes)}';

      expect(ServiceImageResolver.tryDecodeBytes(dataUri), bytes);
      expect(
        ServiceImageResolver.resolveNetworkUrl('https://cdn.example.com/a.png'),
        'https://cdn.example.com/a.png',
      );
      expect(
        ServiceImageResolver.resolveNetworkUrl('/uploads/a.png'),
        'http://localhost:8085/uploads/a.png',
      );
    });
  });
}
