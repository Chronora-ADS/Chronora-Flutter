import 'dart:convert';

import '../api/api_service.dart';
import 'auth_session_service.dart';

class ModeratorService {
  Future<List<PaymentTransactionSummary>> getAllTransactions() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Nao autenticado.');

    final response =
        await ApiService.get('/moderator/transactions', token: token);

    if (response.statusCode != 200) {
      throw Exception(ApiService.extractErrorMessage(response.body,
          fallback: 'Erro ao carregar transacoes.'));
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => PaymentTransactionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class PaymentTransactionSummary {
  final int id;
  final int userId;
  final String userName;
  final String type;
  final String status;
  final int chronosAmount;
  final double totalAmount;
  final DateTime createdAt;
  final bool isPix;

  const PaymentTransactionSummary({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.status,
    required this.chronosAmount,
    required this.totalAmount,
    required this.createdAt,
    required this.isPix,
  });

  factory PaymentTransactionSummary.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionSummary(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? 'Desconhecido',
      type: json['type'] as String,
      status: json['status'] as String,
      chronosAmount: json['chronosAmount'] as int,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPix: json['isPix'] as bool? ?? false,
    );
  }

  bool get isBuy => type == 'BUY';
  bool get isPaid => status == 'PAID';
  bool get isPending => status == 'PENDING';
  bool get isFailed => status == 'FAILED';
}
