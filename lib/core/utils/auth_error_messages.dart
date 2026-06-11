import '../api/api_service.dart';

const String registrationConflictMessage =
    'E-mail ou telefone ja cadastrado. Use outros dados para criar a conta.';

String resolveRegistrationErrorMessage(int statusCode, String responseBody) {
  if (statusCode == 409) {
    return registrationConflictMessage;
  }

  return ApiService.extractErrorMessage(
    responseBody,
    fallback: 'Nao foi possivel concluir o cadastro.',
  );
}
