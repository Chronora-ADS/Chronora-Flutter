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

  Future<List<ModeratorUser>> getAllUsers() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Nao autenticado.');

    final response = await ApiService.get('/moderator/users', token: token);

    if (response.statusCode != 200) {
      throw Exception(ApiService.extractErrorMessage(response.body,
          fallback: 'Erro ao carregar usuarios.'));
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ModeratorUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ModeratorService2>> getAllServices() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Nao autenticado.');

    final response = await ApiService.get('/moderator/services', token: token);

    if (response.statusCode != 200) {
      throw Exception(ApiService.extractErrorMessage(response.body,
          fallback: 'Erro ao carregar pedidos.'));
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ModeratorService2.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PaymentTransactionSummary>> getBuyTransactions() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Nao autenticado.');

    final response =
        await ApiService.get('/moderator/transactions/buy', token: token);

    if (response.statusCode != 200) {
      throw Exception(ApiService.extractErrorMessage(response.body,
          fallback: 'Erro ao carregar compras.'));
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => PaymentTransactionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PaymentTransactionSummary>> getSellTransactions() async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Nao autenticado.');

    final response =
        await ApiService.get('/moderator/transactions/sell', token: token);

    if (response.statusCode != 200) {
      throw Exception(ApiService.extractErrorMessage(response.body,
          fallback: 'Erro ao carregar vendas.'));
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => PaymentTransactionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markSellAsPaid(int id) async {
    final token = await AuthSessionService.getValidAccessToken();
    if (token == null) throw Exception('Nao autenticado.');

    final response = await ApiService.patch(
      '/moderator/sell/$id/mark-paid',
      {},
      token: token,
    );

    if (response.statusCode != 200) {
      throw Exception(ApiService.extractErrorMessage(response.body,
          fallback: 'Erro ao marcar venda como paga.'));
    }
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
  final int? mpPaymentId;
  final String? pixKey;

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
    this.mpPaymentId,
    this.pixKey,
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
      mpPaymentId: json['mpPaymentId'] as int?,
      pixKey: json['pixKey'] as String?,
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

class ModeratorUser {
  final int id;
  final String name;
  final String email;
  final int timeChronos;
  final double rating;
  final String? profileImage;
  final List<String> roles;

  const ModeratorUser({
    required this.id,
    required this.name,
    required this.email,
    required this.timeChronos,
    required this.rating,
    this.profileImage,
    required this.roles,
  });

  bool get isModerator => roles.contains('ROLE_MODERATOR');

  factory ModeratorUser.fromJson(Map<String, dynamic> json) {
    return ModeratorUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Sem nome',
      email: json['email'] as String? ?? '',
      timeChronos: json['timeChronos'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      profileImage: json['profileImage'] as String?,
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class ModeratorService2 {
  final int id;
  final String title;
  final String status;
  final String modality;
  final int timeChronos;
  final DateTime deadline;
  final DateTime postedAt;
  final String creatorName;
  final int? creatorId;
  final String? acceptedName;
  final int? acceptedId;
  final List<String> categories;

  const ModeratorService2({
    required this.id,
    required this.title,
    required this.status,
    required this.modality,
    required this.timeChronos,
    required this.deadline,
    required this.postedAt,
    required this.creatorName,
    this.creatorId,
    this.acceptedName,
    this.acceptedId,
    required this.categories,
  });

  factory ModeratorService2.fromJson(Map<String, dynamic> json) {
    return ModeratorService2(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      modality: json['modality'] as String,
      timeChronos: json['timeChronos'] as int,
      deadline: DateTime.parse(json['deadline'] as String),
      postedAt: DateTime.parse(json['postedAt'] as String),
      creatorName: json['creatorName'] as String? ?? 'Desconhecido',
      creatorId: json['creatorId'] as int?,
      acceptedName: json['acceptedName'] as String?,
      acceptedId: json['acceptedId'] as int?,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
