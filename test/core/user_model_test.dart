import 'package:chronora/core/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Funcionalidade: Perfil do usuario', () {
    test('parseia avaliacao e imagem de perfil', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Ana Silva',
        'email': 'ana@chronora.com',
        'phoneNumber': 11999999999,
        'timeChronos': 80,
        'rating': '4,5',
        'profileImage': 'https://storage/avatar.jpg',
      });

      expect(user.rating, 4.5);
      expect(user.profileImage, 'https://storage/avatar.jpg');
    });
  });
}
