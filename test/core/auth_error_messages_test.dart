import 'package:chronora/core/utils/auth_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveRegistrationErrorMessage', () {
    test('retorna mensagem amigavel quando cadastro retorna conflito vazio',
        () {
      final message = resolveRegistrationErrorMessage(409, '');

      expect(message, registrationConflictMessage);
    });

    test('usa mensagem do backend quando erro nao e conflito', () {
      final message = resolveRegistrationErrorMessage(
        400,
        '{"message":"Dados invalidos."}',
      );

      expect(message, 'Dados invalidos.');
    });
  });
}
