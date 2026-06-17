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

  Future<PlatformStats> getStats() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Nao autenticado.');

    final response = await ApiService.get('/moderator/stats', token: token);

    if (response.statusCode != 200) {
      throw Exception(ApiService.extractErrorMessage(response.body,
          fallback: 'Erro ao carregar estatisticas.'));
    }

    return PlatformStats.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
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

class PlatformStats {
  final int totalUsuarios;
  final int totalPedidos;
  final int pedidosCriados;
  final int pedidosEmAndamento;
  final int pedidosConcluidos;
  final int pedidosCancelados;
  final int totalTransacoes;
  final int transacoesPagas;
  final int transacoesPendentes;
  final int transacoesFalhas;
  final int totalChronosComprados;
  final int totalChronosVendidos;
  final double volumeFinanceiroTotal;

  const PlatformStats({
    required this.totalUsuarios,
    required this.totalPedidos,
    required this.pedidosCriados,
    required this.pedidosEmAndamento,
    required this.pedidosConcluidos,
    required this.pedidosCancelados,
    required this.totalTransacoes,
    required this.transacoesPagas,
    required this.transacoesPendentes,
    required this.transacoesFalhas,
    required this.totalChronosComprados,
    required this.totalChronosVendidos,
    required this.volumeFinanceiroTotal,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      totalUsuarios: json['totalUsuarios'] as int,
      totalPedidos: json['totalPedidos'] as int,
      pedidosCriados: json['pedidosCriados'] as int,
      pedidosEmAndamento: json['pedidosEmAndamento'] as int,
      pedidosConcluidos: json['pedidosConcluidos'] as int,
      pedidosCancelados: json['pedidosCancelados'] as int,
      totalTransacoes: json['totalTransacoes'] as int,
      transacoesPagas: json['transacoesPagas'] as int,
      transacoesPendentes: json['transacoesPendentes'] as int,
      transacoesFalhas: json['transacoesFalhas'] as int,
      totalChronosComprados: json['totalChronosComprados'] as int,
      totalChronosVendidos: json['totalChronosVendidos'] as int,
      volumeFinanceiroTotal: (json['volumeFinanceiroTotal'] as num).toDouble(),
    );
  }
}
