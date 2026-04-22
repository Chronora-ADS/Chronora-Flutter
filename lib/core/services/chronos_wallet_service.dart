import 'dart:convert';

import 'package:http/http.dart' as http;

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

  Future<void> buyChronos(int amount) async {
    await _sendChronosUpdate('/user/put/buy-chronos', amount);
  }

  Future<void> sellChronos({
    required int amount,
    String? pixKey,
  }) async {
    await _sendChronosUpdate(
      '/user/put/sell-chronos',
      amount,
      pixKey: pixKey,
    );
  }

  int _extractChronosBalance(String responseBody) {
    final dynamic decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return _toInt(decoded['timeChronos']);
    }
    return 0;
  }

  Future<void> _sendChronosUpdate(
    String endpoint,
    int amount, {
    String? pixKey,
  }) async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) {
      throw Exception('Token de autenticacao nao encontrado.');
    }

    final headers = <String, String>{
      'Chronos': amount.toString(),
      'Authorization': 'Bearer $token',
      if (pixKey != null && pixKey.trim().isNotEmpty) 'Pix-Key': pixKey.trim(),
    };

    final response = await ApiService.putWithHeaders(endpoint, headers);
    _ensureSuccess(response);
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      ApiService.extractErrorMessage(
        response.body,
        fallback: 'Nao foi possivel processar a operacao com Chronos.',
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
