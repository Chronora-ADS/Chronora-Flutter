import '../api/api_service.dart';

const String registrationConflictMessage =
    'E-mail ou telefone já cadastrado. Use outros dados para criar a conta.';

String resolveRegistrationErrorMessage(int statusCode, String responseBody) {
  if (statusCode == 409) {
    return registrationConflictMessage;
  }

  return ApiService.extractErrorMessage(
    responseBody,
    fallback: 'Não foi possível concluir o cadastro.',
  );
}
