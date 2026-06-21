import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_service.dart';
import '../constants/app_config.dart';
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

  Future<Map<String, dynamic>> fetchChronosConfig() async {
    final response = await ApiService.get('/payment/config');
    if (response.statusCode != 200) {
      throw Exception('Nao foi possivel carregar configuracao de precos.');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
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
      qrCode: data['qrCode'] as String? ?? '',
      qrCodeBase64: '',
      expiresAt: data['expiresAt'] != null
          ? DateTime.parse(data['expiresAt'] as String)
          : DateTime.now().add(const Duration(minutes: 5)),
      status: data['status'] as String? ?? 'PENDING',
      paymentMethod: data['paymentMethod'] as String? ?? 'PIX',
    );
  }

  Future<BuyPaymentResponse> createBuyPayment(int chronosAmount) async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Usuario nao autenticado.');

    final response = await ApiService.post(
      '/payment/buy/create',
      {'chronosAmount': chronosAmount, 'paymentMethod': 'PIX'},
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
      status: data['status'] as String? ?? 'PENDING',
      paymentMethod: 'PIX',
    );
  }

  Future<CardTokenResult> tokenizeCard({
    required String cardNumber,
    required String expirationMonth,
    required String expirationYear,
    required String securityCode,
    required String cardholderName,
    required String docNumber,
  }) async {
    final uri = Uri.parse(
        'https://api.mercadopago.com/v1/card_tokens?public_key=${AppConfig.mpPublicKey}');

    final body = jsonEncode({
      'card_number': cardNumber.replaceAll(' ', ''),
      'expiration_month': int.parse(expirationMonth),
      'expiration_year': int.parse('20$expirationYear'),
      'security_code': securityCode,
      'cardholder': {
        'name': cardholderName,
        'identification': {
          'type': 'CPF',
          'number': docNumber.replaceAll(RegExp(r'\D'), ''),
        },
      },
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final detail = _extractMpError(response.body);
      throw Exception('Erro ao processar cartao: $detail');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final paymentMethodId = data['payment_method_id'] as String?
        ?? _inferPaymentMethod(cardNumber);

    return CardTokenResult(
      token: data['id'] as String,
      paymentMethodId: paymentMethodId,
    );
  }

  String _inferPaymentMethod(String cardNumber) {
    final firstDigit = cardNumber.replaceAll(' ', '')[0];
    switch (firstDigit) {
      case '4': return 'visa';
      case '3': return 'amex';
      default:  return 'master';
    }
  }

  Future<CardBuyResponse> createCardBuyPayment({
    required int chronosAmount,
    required String cardToken,
    required String cardPaymentMethodId,
    required String payerDocNumber,
    int installments = 1,
  }) async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Usuario nao autenticado.');

    final response = await ApiService.post(
      '/payment/buy/create',
      {
        'chronosAmount': chronosAmount,
        'paymentMethod': 'CREDIT_CARD',
        'cardToken': cardToken,
        'cardPaymentMethodId': cardPaymentMethodId,
        'installments': installments,
        'payerDocNumber': payerDocNumber,
      },
      token: token,
    );

    if (response.statusCode != 200) {
      throw Exception(ApiService.extractErrorMessage(response.body,
          fallback: 'Pagamento recusado. Verifique os dados do cartao.'));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CardBuyResponse(
      transactionId: data['transactionId'] as int,
      status: data['status'] as String,
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

  String _extractMpError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['message'] as String? ?? body;
    } catch (_) {
      return body;
    }
  }
}

class BuyPaymentResponse {
  final int transactionId;
  final String qrCode;
  final String qrCodeBase64;
  final DateTime expiresAt;
  final String status;
  final String paymentMethod;

  const BuyPaymentResponse({
    required this.transactionId,
    required this.qrCode,
    required this.qrCodeBase64,
    required this.expiresAt,
    this.status = 'PENDING',
    this.paymentMethod = 'PIX',
  });
}

class CardTokenResult {
  final String token;
  final String paymentMethodId;

  const CardTokenResult({required this.token, required this.paymentMethodId});
}

class CardBuyResponse {
  final int transactionId;
  final String status;

  const CardBuyResponse({required this.transactionId, required this.status});
}
