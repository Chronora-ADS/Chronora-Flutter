import 'dart:convert';

import '../api/api_service.dart';
import 'auth_session_service.dart';

class ChronosWalletService {
  Future<int> fetchCurrentBalance() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) {
      throw Exception('Usuario nao autenticado.');
    }

    final response = await ApiService.get('/user/get', token: token);
    if (response.statusCode != 200) {
      throw Exception(
        ApiService.extractErrorMessage(
          response.body,
          fallback: 'Nao foi possivel carregar o saldo atual.',
        ),
      );
    }

    return _extractChronosBalance(response.body);
  }

  Future<BuyPaymentResponse?> fetchPendingBuyPayment() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) return null;

    final response = await ApiService.get('/payment/buy/pending', token: token);
    if (response.statusCode == 204) return null;
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return BuyPaymentResponse(
      transactionId: data['transactionId'] as int,
      qrCode: data['qrCode'] as String,
      qrCodeBase64: '',
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }

  Future<BuyPaymentResponse> createBuyPayment(int chronosAmount) async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Usuario nao autenticado.');

    final response = await ApiService.post(
      '/payment/buy/create',
      {'chronosAmount': chronosAmount},
      token: token,
    );

    if (response.statusCode != 200) {
      throw Exception(ApiService.extractErrorMessage(response.body,
          fallback: 'Nao foi possivel iniciar o pagamento.'));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return BuyPaymentResponse(
      transactionId: data['transactionId'] as int,
      qrCode: data['qrCode'] as String,
      qrCodeBase64: data['qrCodeBase64'] as String,
      expiresAt: DateTime.parse(data['expiresAt'] as String),
    );
  }

  Future<String> checkBuyPaymentStatus(int transactionId) async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Usuario nao autenticado.');

    final response =
        await ApiService.get('/payment/buy/status/$transactionId', token: token);

    if (response.statusCode != 200) {
      throw Exception(ApiService.extractErrorMessage(response.body));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['status'] as String;
  }

  Future<void> createSellPayment({
    required int chronosAmount,
    required String pixKey,
  }) async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Usuario nao autenticado.');

    final response = await ApiService.post(
      '/payment/sell/create',
      {'chronosAmount': chronosAmount, 'pixKey': pixKey},
      token: token,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(ApiService.extractErrorMessage(response.body,
          fallback: 'Nao foi possivel processar a venda.'));
    }
  }

  int _extractChronosBalance(String responseBody) {
    final dynamic decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return _toInt(decoded['timeChronos']);
    }
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class BuyPaymentResponse {
  final int transactionId;
  final String qrCode;
  final String qrCodeBase64;
  final DateTime expiresAt;

  const BuyPaymentResponse({
    required this.transactionId,
    required this.qrCode,
    required this.qrCodeBase64,
    required this.expiresAt,
  });
}
