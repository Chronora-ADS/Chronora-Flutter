import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/moderator_service.dart';

class ModeratorPanelPage extends StatelessWidget {
  const ModeratorPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.preto,
        appBar: AppBar(
          backgroundColor: AppColors.amareloUmPoucoEscuro,
          foregroundColor: AppColors.branco,
          title: const Text(
            'Painel do Moderador',
            style: TextStyle(
              color: AppColors.branco,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.branco,
            labelColor: AppColors.branco,
            unselectedLabelColor: AppColors.amareloMuitoEscura,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Usuários'),
              Tab(text: 'Pedidos'),
              Tab(text: 'Denúncias'),
              Tab(text: 'Estatísticas'),
              Tab(text: 'Transações'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PlaceholderTab(label: 'Usuários'),
            _PlaceholderTab(label: 'Pedidos'),
            _PlaceholderTab(label: 'Denúncias'),
            _PlaceholderTab(label: 'Estatísticas'),
            _TransacoesTab(),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String label;

  const _PlaceholderTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 64, color: AppColors.amareloClaro),
          const SizedBox(height: 16),
          Text(
            '$label em breve',
            style: const TextStyle(
              color: AppColors.branco,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esta aba ainda está sendo implementada.',
            style: TextStyle(color: AppColors.cinza, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _TransacoesTab extends StatefulWidget {
  const _TransacoesTab();

  @override
  State<_TransacoesTab> createState() => _TransacoesTabState();
}

class _TransacoesTabState extends State<_TransacoesTab>
    with AutomaticKeepAliveClientMixin {
  final _service = ModeratorService();
  late Future<List<PaymentTransactionSummary>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllTransactions();
  }

  void _reload() {
    setState(() {
      _future = _service.getAllTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<PaymentTransactionSummary>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.amareloClaro),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.vermelho),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.branco),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _reload,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amareloUmPoucoEscuro),
                    child: const Text('Tentar novamente',
                        style: TextStyle(color: AppColors.branco)),
                  ),
                ],
              ),
            ),
          );
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Center(
            child: Text(
              'Nenhuma transação encontrada.',
              style: TextStyle(color: AppColors.cinza, fontSize: 16),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.amareloClaro,
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: transactions.length,
            itemBuilder: (context, index) =>
                _TransactionCard(transaction: transactions[index]),
          ),
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final PaymentTransactionSummary transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final dateFormatted =
        DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt.toLocal());

    Color statusColor;
    String statusLabel;
    switch (t.status) {
      case 'PAID':
        statusColor = Colors.greenAccent;
        statusLabel = 'Pago';
      case 'PENDING':
        statusColor = Colors.orangeAccent;
        statusLabel = 'Pendente';
      default:
        statusColor = AppColors.vermelho;
        statusLabel = 'Falhou';
    }

    final typeLabel = t.isBuy ? 'Compra' : 'Venda';
    final typeColor = t.isBuy ? Colors.blueAccent : Colors.greenAccent;
    final paymentLabel = t.isPix ? 'PIX' : 'Cartão';

    return Card(
      color: const Color(0xFF1A1B1E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _Chip(label: typeLabel, color: typeColor),
                    const SizedBox(width: 6),
                    _Chip(label: paymentLabel, color: AppColors.amareloClaro),
                  ],
                ),
                _Chip(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.cinza),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.userName,
                    style: const TextStyle(
                      color: AppColors.branco,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '#${t.id}',
                  style: const TextStyle(color: AppColors.cinza, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: AppColors.cinza),
                    const SizedBox(width: 4),
                    Text(
                      dateFormatted,
                      style: const TextStyle(
                          color: AppColors.cinza, fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '${t.chronosAmount} Chronos',
                      style: const TextStyle(
                        color: AppColors.amareloClaro,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'R\$ ${t.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.branco,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
