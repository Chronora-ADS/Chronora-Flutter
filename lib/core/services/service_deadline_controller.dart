import '../api/api_service.dart';
import '../../widgets/notification_card.dart';
import 'auth_session_service.dart';

class ServiceDeadlineController {
  static const String deadlineActionMessageStart = 'Prazo do pedido chegou';

  static bool canRespondToDeadline(NotificationEntry notification) {
    final isDeadlineNotification =
        notification.message.startsWith(deadlineActionMessageStart);
    final serviceStatus = notification.service.status.toUpperCase();

    return isDeadlineNotification &&
        notification.service.id > 0 &&
        (serviceStatus.isEmpty || serviceStatus == 'CRIADO');
  }

  Future<void> renewDeadline({
    required int serviceId,
    required DateTime deadline,
  }) async {
    final token = await _getToken();
    final response = await ApiService.put(
      '/service/renewDeadline/$serviceId',
      {'deadline': _formatDate(deadline)},
      token: token,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiService.extractErrorMessage(
          response.body,
          fallback: 'Nao foi possivel renovar o prazo.',
        ),
      );
    }
  }

  Future<void> cancelService({required int serviceId}) async {
    final token = await _getToken();
    final response = await ApiService.put(
      '/service/cancelService/$serviceId',
      const {},
      token: token,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        ApiService.extractErrorMessage(
          response.body,
          fallback: 'Nao foi possivel cancelar o pedido.',
        ),
      );
    }
  }

  Future<String> _getToken() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) {
      throw Exception('Usuario nao autenticado.');
    }
    return token;
  }

  String _formatDate(DateTime value) {
    final dateOnly = DateTime(value.year, value.month, value.day);
    return dateOnly.toIso8601String().split('T').first;
  }
}
