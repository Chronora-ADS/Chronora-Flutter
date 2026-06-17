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
            unselectedLabelColor: Color(0xAAE9EAEC),
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              Tab(text: 'Usuários'),
              Tab(text: 'Pedidos'),
              Tab(text: 'Denúncias'),
              Tab(text: 'Estatísticas'),
              Tab(text: 'Webhooks'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _UsuariosTab(),
            const _PedidosTab(),
            const _PlaceholderTab(label: 'Denúncias'),
            const _EstatisticasTab(),
            const _TransacoesTab(),
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

class _UsuariosTab extends StatefulWidget {
  const _UsuariosTab();

  @override
  State<_UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<_UsuariosTab>
    with AutomaticKeepAliveClientMixin {
  final _service = ModeratorService();
  late Future<List<ModeratorUser>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllUsers();
  }

  void _reload() => setState(() => _future = _service.getAllUsers());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<ModeratorUser>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.amareloClaro));
        }
        if (snapshot.hasError) {
          return _ErrorView(
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload);
        }
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(
              child: Text('Nenhum usuário encontrado.',
                  style: TextStyle(color: AppColors.cinza, fontSize: 16)));
        }
        return RefreshIndicator(
          color: AppColors.amareloClaro,
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) =>
                _UserCard(user: users[index]),
          ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final ModeratorUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final hasPhoto = user.profileImage != null && user.profileImage!.isNotEmpty;

    return Card(
      color: const Color(0xFF1A1B1E),
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.amareloUmPoucoEscuro,
              backgroundImage: hasPhoto ? NetworkImage(user.profileImage!) : null,
              child: !hasPhoto
                  ? Text(initial,
                      style: const TextStyle(
                          color: AppColors.branco,
                          fontWeight: FontWeight.w700,
                          fontSize: 18))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(user.name,
                            style: const TextStyle(
                                color: AppColors.branco,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (user.isModerator)
                        const _Chip(label: 'Mod', color: AppColors.amareloClaro),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: const TextStyle(
                          color: AppColors.cinza, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppColors.amareloClaro),
                      const SizedBox(width: 4),
                      Text(user.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: AppColors.branco, fontSize: 12)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time,
                          size: 14, color: AppColors.cinza),
                      const SizedBox(width: 4),
                      Text('${user.timeChronos} Chronos',
                          style: const TextStyle(
                              color: AppColors.cinza, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PedidosTab extends StatefulWidget {
  const _PedidosTab();

  @override
  State<_PedidosTab> createState() => _PedidosTabState();
}

class _PedidosTabState extends State<_PedidosTab>
    with AutomaticKeepAliveClientMixin {
  final _service = ModeratorService();
  late Future<List<ModeratorService2>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllServices();
  }

  void _reload() => setState(() => _future = _service.getAllServices());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<ModeratorService2>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.amareloClaro));
        }
        if (snapshot.hasError) {
          return _ErrorView(
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload);
        }
        final services = snapshot.data ?? [];
        if (services.isEmpty) {
          return const Center(
              child: Text('Nenhum pedido encontrado.',
                  style: TextStyle(color: AppColors.cinza, fontSize: 16)));
        }
        return RefreshIndicator(
          color: AppColors.amareloClaro,
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: services.length,
            itemBuilder: (context, index) =>
                _ServiceCard(service: services[index]),
          ),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ModeratorService2 service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final s = service;
    final deadlineFormatted =
        DateFormat('dd/MM/yyyy').format(s.deadline.toLocal());

    Color statusColor;
    String statusLabel;
    switch (s.status) {
      case 'CRIADO':
        statusColor = Colors.blueAccent;
        statusLabel = 'Criado';
      case 'ACEITO':
        statusColor = Colors.purpleAccent;
        statusLabel = 'Aceito';
      case 'EM_ANDAMENTO':
        statusColor = Colors.orangeAccent;
        statusLabel = 'Em andamento';
      case 'CONCLUIDO':
        statusColor = Colors.greenAccent;
        statusLabel = 'Concluído';
      case 'CANCELADO':
        statusColor = AppColors.vermelho;
        statusLabel = 'Cancelado';
      default:
        statusColor = AppColors.cinza;
        statusLabel = s.status;
    }

    final isRemote = s.modality == 'REMOTO';

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
                    _Chip(label: statusLabel, color: statusColor),
                    const SizedBox(width: 6),
                    _Chip(
                      label: isRemote ? 'Remoto' : 'Presencial',
                      color: isRemote ? Colors.blueAccent : Colors.tealAccent,
                    ),
                  ],
                ),
                Text('#${s.id}',
                    style: const TextStyle(
                        color: AppColors.cinza, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.title,
                style: const TextStyle(
                    color: AppColors.branco,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppColors.cinza),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Criador: ${s.creatorName}',
                      style: const TextStyle(
                          color: AppColors.cinza, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            if (s.acceptedName != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.handshake_outlined,
                      size: 14, color: AppColors.cinza),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text('Prestador: ${s.acceptedName}',
                        style: const TextStyle(
                            color: AppColors.cinza, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 13, color: AppColors.cinza),
                    const SizedBox(width: 4),
                    Text('Prazo: $deadlineFormatted',
                        style: const TextStyle(
                            color: AppColors.cinza, fontSize: 12)),
                  ],
                ),
                Text('${s.timeChronos} Chronos',
                    style: const TextStyle(
                        color: AppColors.amareloClaro,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.vermelho),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.branco)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
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
}

class _EstatisticasTab extends StatefulWidget {
  const _EstatisticasTab();

  @override
  State<_EstatisticasTab> createState() => _EstatisticasTabState();
}

class _EstatisticasTabState extends State<_EstatisticasTab>
    with AutomaticKeepAliveClientMixin {
  final _service = ModeratorService();
  late Future<PlatformStats> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _service.getStats();
  }

  void _reload() => setState(() => _future = _service.getStats());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<PlatformStats>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.amareloClaro));
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

        final s = snapshot.data!;
        return RefreshIndicator(
          color: AppColors.amareloClaro,
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatSection(title: 'Usuários', children: [
                _StatTile(label: 'Total de usuários', value: '${s.totalUsuarios}',
                    icon: Icons.people),
              ]),
              const SizedBox(height: 16),
              _StatSection(title: 'Pedidos', children: [
                _StatTile(label: 'Total', value: '${s.totalPedidos}',
                    icon: Icons.list_alt),
                _StatTile(label: 'Criados', value: '${s.pedidosCriados}',
                    icon: Icons.pending_outlined, color: Colors.blueAccent),
                _StatTile(label: 'Em andamento', value: '${s.pedidosEmAndamento}',
                    icon: Icons.autorenew, color: Colors.orangeAccent),
                _StatTile(label: 'Concluídos', value: '${s.pedidosConcluidos}',
                    icon: Icons.check_circle_outline, color: Colors.greenAccent),
                _StatTile(label: 'Cancelados', value: '${s.pedidosCancelados}',
                    icon: Icons.cancel_outlined, color: AppColors.vermelho),
              ]),
              const SizedBox(height: 16),
              _StatSection(title: 'Transações', children: [
                _StatTile(label: 'Total', value: '${s.totalTransacoes}',
                    icon: Icons.receipt_long),
                _StatTile(label: 'Pagas', value: '${s.transacoesPagas}',
                    icon: Icons.check_circle_outline, color: Colors.greenAccent),
                _StatTile(label: 'Pendentes', value: '${s.transacoesPendentes}',
                    icon: Icons.hourglass_empty, color: Colors.orangeAccent),
                _StatTile(label: 'Falhas', value: '${s.transacoesFalhas}',
                    icon: Icons.error_outline, color: AppColors.vermelho),
              ]),
              const SizedBox(height: 16),
              _StatSection(title: 'Chronos', children: [
                _StatTile(label: 'Comprados', value: '${s.totalChronosComprados}',
                    icon: Icons.arrow_downward, color: Colors.greenAccent),
                _StatTile(label: 'Vendidos', value: '${s.totalChronosVendidos}',
                    icon: Icons.arrow_upward, color: Colors.blueAccent),
                _StatTile(
                    label: 'Volume financeiro',
                    value: 'R\$ ${s.volumeFinanceiroTotal.toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                    color: AppColors.amareloClaro),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _StatSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _StatSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.amareloClaro,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.branco,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(color: AppColors.cinza, fontSize: 14))),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w700)),
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

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays < 7) return 'há ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;

    Color statusColor;
    IconData statusIcon;
    String title;

    if (t.isPaid) {
      statusColor = Colors.greenAccent;
      statusIcon = t.isBuy ? Icons.arrow_circle_down : Icons.arrow_circle_up;
      title = t.isBuy
          ? 'Compra de ${t.chronosAmount} Chronos aprovada'
          : 'Venda de ${t.chronosAmount} Chronos concluída';
    } else if (t.isPending) {
      statusColor = Colors.orangeAccent;
      statusIcon = Icons.hourglass_top_rounded;
      title = t.isBuy
          ? 'Compra de ${t.chronosAmount} Chronos aguardando pagamento'
          : 'Venda de ${t.chronosAmount} Chronos pendente';
    } else {
      statusColor = AppColors.vermelho;
      statusIcon = Icons.cancel_outlined;
      title = t.isBuy
          ? 'Compra de ${t.chronosAmount} Chronos falhou'
          : 'Venda de ${t.chronosAmount} Chronos recusada';
    }

    final paymentLabel = t.isPix ? 'PIX' : 'Cartão';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1B1E),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.branco,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.userName,
                    style: const TextStyle(
                        color: AppColors.cinza, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Chip(label: paymentLabel, color: AppColors.amareloClaro),
                      const SizedBox(width: 6),
                      Text(
                        'R\$ ${t.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.branco,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _timeAgo(t.createdAt),
              style: const TextStyle(color: AppColors.cinza, fontSize: 11),
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
