import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_session_service.dart';

class ExtratoPage extends StatefulWidget {
  const ExtratoPage({super.key});

  @override
  State<ExtratoPage> createState() => _ExtratoPageState();
}

class _ExtratoPageState extends State<ExtratoPage> {
  List<_ExtractItem> _items = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) throw Exception('Usuário não autenticado.');
      final response = await ApiService.get('/payment/history', token: token);
      if (response.statusCode != 200) {
        throw Exception('Não foi possível carregar o extrato.');
      }
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _items = data
            .map((e) => _ExtractItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      appBar: AppBar(
        backgroundColor: AppColors.preto,
        foregroundColor: AppColors.branco,
        title: const Text(
          'Extrato de Chronos',
          style: TextStyle(
            color: AppColors.branco,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.amareloClaro),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.vermelho, size: 48),
            const SizedBox(height: 12),
            Text(
              'Erro ao carregar extrato',
              style: const TextStyle(color: AppColors.branco, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _fetch();
              },
              child: const Text('Tentar novamente',
                  style: TextStyle(color: AppColors.amareloClaro)),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, color: Color(0xFF555555), size: 64),
            SizedBox(height: 16),
            Text(
              'Nenhuma transação encontrada',
              style: TextStyle(color: Color(0xFF888888), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      color: AppColors.amareloClaro,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildItem(_items[index]),
      ),
    );
  }

  Widget _buildItem(_ExtractItem item) {
    final isGain = item.chronosAmount > 0;
    final amount = item.chronosAmount.abs();
    final color = isGain ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final amountStr = isGain ? '+$amount' : '-$amount';

    final typeLabel = switch (item.type) {
      'COMPRA' => 'Compra de Chronos',
      'VENDA' => 'Venda de Chronos',
      'PEDIDO_CRIADO' => 'Pedido criado',
      'RECEBIMENTO_SERVICO' => 'Serviço prestado',
      _ => item.type,
    };

    final d = item.date;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGain ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(
                    color: AppColors.branco,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                          color: Color(0xFF666666), fontSize: 11),
                    ),
                    if (item.status == 'PENDENTE') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA500).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Pendente',
                          style: TextStyle(
                              color: Color(0xFFFFA500), fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Text(
                amountStr,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 4),
              Image.asset('assets/img/Coin.png', width: 18, height: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExtractItem {
  final String type;
  final int chronosAmount;
  final DateTime date;
  final String description;
  final String? status;

  const _ExtractItem({
    required this.type,
    required this.chronosAmount,
    required this.date,
    required this.description,
    this.status,
  });

  factory _ExtractItem.fromJson(Map<String, dynamic> json) {
    return _ExtractItem(
      type: json['type'] as String,
      chronosAmount: (json['chronosAmount'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String,
      status: json['status'] as String?,
    );
  }
}
