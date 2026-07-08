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
  List<_ExtractItem> _allItems = const [];
  String? _selectedFilter;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasNextPage = false;
  int _currentPage = 0;
  String? _error;

  static const _filters = [
    (label: 'Todos', value: null),
    (label: 'Compras', value: 'COMPRA'),
    (label: 'Vendas', value: 'VENDA'),
    (label: 'Pedidos', value: 'PEDIDO_CRIADO'),
    (label: 'Recebimentos', value: 'RECEBIMENTO_SERVICO'),
  ];

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
  }

  Future<void> _fetch({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _allItems = const [];
        _hasNextPage = false;
        _isLoading = true;
        _error = null;
      });
    } else {
      if (!_hasNextPage || _isLoadingMore) return;
      setState(() => _isLoadingMore = true);
    }

    final page = _currentPage;
    final type = _selectedFilter;

    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) throw Exception('Usuário não autenticado.');

      final typeParam = type != null ? '&type=$type' : '';
      final response = await ApiService.get(
        '/payment/history?page=$page&size=20$typeParam',
        token: token,
      );
      if (response.statusCode != 200) {
        throw Exception('Não foi possível carregar o extrato.');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['content'] as List<dynamic>;
      final isLast = (decoded['last'] as bool?) ?? true;

      if (!mounted) return;
      final newItems = content
          .map((e) => _ExtractItem.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _allItems = page == 0 ? newItems : [..._allItems, ...newItems];
        _hasNextPage = !isLast;
        _currentPage = page + 1;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (page == 0) _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
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
            const Text(
              'Erro ao carregar extrato',
              style: TextStyle(color: AppColors.branco, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetch,
              child: const Text('Tentar novamente',
                  style: TextStyle(color: AppColors.amareloClaro)),
            ),
          ],
        ),
      );
    }

    final items = _allItems;
    final grouped = _groupByPeriod(items);

    return Column(
      children: [
        _buildFilterRow(),
        Expanded(
          child: items.isEmpty
              ? const Center(
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
                )
              : RefreshIndicator(
                  onRefresh: () => _fetch(reset: true),
                  color: AppColors.amareloClaro,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: grouped.length + (_hasNextPage || _isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == grouped.length) {
                        return _isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.amareloClaro,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 16),
                                child: ElevatedButton(
                                  onPressed: _fetch,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    foregroundColor: AppColors.amareloClaro,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Carregar mais',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              );
                      }
                      final entry = grouped[index];
                      if (entry is _PeriodHeader) {
                        return _buildPeriodHeader(entry.label);
                      }
                      return _buildItem(entry as _ExtractItem);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _filters[i];
          final selected = _selectedFilter == f.value;
          return GestureDetector(
            onTap: () {
              if (_selectedFilter == f.value) return;
              setState(() => _selectedFilter = f.value);
              _fetch(reset: true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.amareloClaro
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.amareloClaro
                      : const Color(0xFF333333),
                ),
              ),
              child: Text(
                f.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.preto : const Color(0xFF888888),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGain
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
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
                          style:
                              TextStyle(color: Color(0xFFFFA500), fontSize: 10),
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

  List<Object> _groupByPeriod(List<_ExtractItem> items) {
    if (items.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);

    final result = <Object>[];
    String? lastPeriod;

    for (final item in items) {
      final d = DateTime(item.date.year, item.date.month, item.date.day);
      final String period;

      if (!d.isBefore(today)) {
        period = 'HOJE';
      } else if (!d.isBefore(startOfWeek)) {
        period = 'ESTA SEMANA';
      } else if (!d.isBefore(startOfMonth)) {
        period = 'ESTE MÊS';
      } else if (!d.isBefore(startOfYear)) {
        final months = [
          '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
          'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
        ];
        period = months[item.date.month].toUpperCase();
      } else {
        period = '${item.date.year}';
      }

      if (period != lastPeriod) {
        result.add(_PeriodHeader(period));
        lastPeriod = period;
      }
      result.add(item);
    }

    return result;
  }
}

class _PeriodHeader {
  final String label;
  const _PeriodHeader(this.label);
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
