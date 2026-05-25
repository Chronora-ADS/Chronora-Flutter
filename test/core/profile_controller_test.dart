import 'dart:convert';

import 'package:chronora/core/api/api_service.dart';
import 'package:chronora/core/services/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    ApiService.setClientForTesting(null);
  });

  group('Funcionalidade: Atualizacao do perfil', () {
    test('envia imagem de perfil no payload de edicao', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'token-valido'});

      late Map<String, dynamic> payload;
      ApiService.setClientForTesting(
        MockClient((request) async {
          payload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 1,
              'name': 'Ana Silva',
              'email': 'ana@chronora.com',
              'phoneNumber': 11999999999,
              'profileImage': 'https://storage/avatar.jpg',
              'rating': 4.5,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final controller = ProfileController();
      final success = await controller.updateUserProfile(
        id: '1',
        name: 'Ana Silva',
        email: 'ana@chronora.com',
        phoneNumber: '(11) 99999-9999',
        profileImage: {
          'name': 'avatar.jpg',
          'type': 'jpg',
          'data': 'base64-avatar',
        },
      );

      expect(success, isTrue);
      expect(payload['profileImage'], {
        'name': 'avatar.jpg',
        'type': 'jpg',
        'data': 'base64-avatar',
      });
      expect(controller.user?.profileImage, 'https://storage/avatar.jpg');
      expect(controller.user?.rating, 4.5);
    });
  });
}
