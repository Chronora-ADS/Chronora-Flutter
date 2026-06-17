import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/moderator_service.dart';
import '../../core/utils/app_snackbar.dart';

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

  // null = Todos, 'PAID', 'PENDING', 'FAILED'
  String? _statusFilter;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _service.getAllTransactions();
  }

  void _reload() => setState(() => _future = _service.getAllTransactions());

  List<PaymentTransactionSummary> _applyFilter(
      List<PaymentTransactionSummary> all) {
    if (_statusFilter == null) return all;
    return all.where((t) {
      if (_statusFilter == 'PAID') return t.isPaid;
      if (_statusFilter == 'PENDING') return t.isPending;
      if (_statusFilter == 'FAILED') return !t.isPaid && !t.isPending;
      return true;
    }).toList();
  }

  String get _statusLabel {
    switch (_statusFilter) {
      case 'PAID':
        return 'Entregue';
      case 'PENDING':
        return 'Pendente';
      case 'FAILED':
        return 'Falhou';
      default:
        return 'Todos';
    }
  }

  void _showStatusPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Filtrar por estado',
                  style: TextStyle(
                      color: AppColors.branco,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
            const Divider(height: 1, color: Color(0xFF2A2D31)),
            _StatusOption(
              label: 'Todos',
              selected: _statusFilter == null,
              onTap: () {
                setState(() => _statusFilter = null);
                Navigator.pop(context);
              },
            ),
            _StatusOption(
              label: 'Entregue',
              dotColor: Colors.greenAccent,
              selected: _statusFilter == 'PAID',
              onTap: () {
                setState(() => _statusFilter = 'PAID');
                Navigator.pop(context);
              },
            ),
            _StatusOption(
              label: 'Pendente',
              dotColor: Colors.orangeAccent,
              selected: _statusFilter == 'PENDING',
              onTap: () {
                setState(() => _statusFilter = 'PENDING');
                Navigator.pop(context);
              },
            ),
            _StatusOption(
              label: 'Falhou',
              dotColor: AppColors.vermelho,
              selected: _statusFilter == 'FAILED',
              onTap: () {
                setState(() => _statusFilter = 'FAILED');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
          return _ErrorView(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            onRetry: _reload,
          );
        }

        final all = snapshot.data ?? [];
        final filtered = _applyFilter(all);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de filtros
            Container(
              color: const Color(0xFF111214),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _FilterChipLabel(
                    label: 'Estado',
                    value: _statusLabel,
                    onTap: _showStatusPicker,
                    active: _statusFilter != null,
                  ),
                  const SizedBox(width: 8),
                  const _FilterChipLabel(label: 'Ambiente', value: 'Produção'),
                  const Spacer(),
                  Text(
                    '${filtered.length} evento${filtered.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: AppColors.cinza, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Cabeçalho das colunas
            Container(
              color: const Color(0xFF16181B),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Row(
                children: [
                  SizedBox(
                      width: 140,
                      child: Text('Status da entrega',
                          style: TextStyle(
                              color: AppColors.cinza,
                              fontSize: 11,
                              fontWeight: FontWeight.w600))),
                  SizedBox(
                      width: 130,
                      child: Text('Ação',
                          style: TextStyle(
                              color: AppColors.cinza,
                              fontSize: 11,
                              fontWeight: FontWeight.w600))),
                  SizedBox(
                      width: 80,
                      child: Text('Evento',
                          style: TextStyle(
                              color: AppColors.cinza,
                              fontSize: 11,
                              fontWeight: FontWeight.w600))),
                  Expanded(
                      child: Text('ID do recurso',
                          style: TextStyle(
                              color: AppColors.cinza,
                              fontSize: 11,
                              fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF2A2D31)),
            // Lista de eventos
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _statusFilter != null
                            ? 'Nenhum evento com status "$_statusLabel".'
                            : 'Nenhum evento encontrado.',
                        style: const TextStyle(
                            color: AppColors.cinza, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.amareloClaro,
                      onRefresh: () async => _reload(),
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: Color(0xFF2A2D31)),
                        itemBuilder: (context, index) =>
                            _WebhookRow(transaction: filtered[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusOption extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final bool selected;
  final VoidCallback onTap;

  const _StatusOption({
    required this.label,
    this.dotColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            if (dotColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: selected
                          ? AppColors.amareloClaro
                          : AppColors.branco,
                      fontSize: 14,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.normal)),
            ),
            if (selected)
              const Icon(Icons.check,
                  size: 18, color: AppColors.amareloClaro),
          ],
        ),
      ),
    );
  }
}

class _FilterChipLabel extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool active;

  const _FilterChipLabel({
    required this.label,
    required this.value,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        active ? AppColors.amareloClaro : const Color(0xFF2A2D31);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2024),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label  ',
                style: const TextStyle(color: AppColors.cinza, fontSize: 12)),
            Text(value,
                style: TextStyle(
                    color: active
                        ? AppColors.amareloClaro
                        : AppColors.branco,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down,
                size: 14,
                color: active ? AppColors.amareloClaro : AppColors.cinza),
          ],
        ),
      ),
    );
  }
}

class _WebhookRow extends StatelessWidget {
  final PaymentTransactionSummary transaction;

  const _WebhookRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;

    Color statusColor;
    String statusLabel;
    int statusCode;

    if (t.isPaid) {
      statusColor = Colors.greenAccent;
      statusLabel = 'Entregue';
      statusCode = 200;
    } else if (t.isPending) {
      statusColor = Colors.orangeAccent;
      statusLabel = 'Pendente';
      statusCode = 202;
    } else {
      statusColor = AppColors.vermelho;
      statusLabel = 'Falhou';
      statusCode = 400;
    }

    final dateFormatted = DateFormat('dd/MM/yyyy, HH:mm:ss')
        .format(t.createdAt.toLocal());
    final resourceId = t.mpPaymentId?.toString() ?? '#${t.id}';

    return InkWell(
      onTap: () => _showDetail(context, t),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status da entrega
                SizedBox(
                  width: 140,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$statusCode - $statusLabel',
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Ação
                SizedBox(
                  width: 130,
                  child: Text(
                    'payment.created',
                    style: TextStyle(
                        color: Colors.orange.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Evento
                const SizedBox(
                  width: 80,
                  child: Text(
                    'payment',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                  ),
                ),
                // ID do recurso
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          resourceId,
                          style: const TextStyle(
                              color: AppColors.branco, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: resourceId));
                          AppSnackBar.show(context, 'ID copiado');
                        },
                        child: const Icon(Icons.copy_outlined,
                            size: 14, color: AppColors.cinza),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.cinza),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                '$dateFormatted (UTC${DateTime.now().timeZoneOffset.isNegative ? '' : '+'}${DateTime.now().timeZoneOffset.inHours}:00)  •  ${t.userName}',
                style: const TextStyle(color: AppColors.cinza, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, PaymentTransactionSummary t) {
    final dateFormatted = DateFormat('dd/MM/yyyy, HH:mm:ss')
        .format(t.createdAt.toLocal());
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: t.isPaid
                        ? Colors.greenAccent
                        : t.isPending
                            ? Colors.orangeAccent
                            : AppColors.vermelho,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  t.isPaid
                      ? '200 - Entregue'
                      : t.isPending
                          ? '202 - Pendente'
                          : '400 - Falhou',
                  style: const TextStyle(
                      color: AppColors.branco,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetailRow(label: 'Ação', value: 'payment.created'),
            _DetailRow(label: 'Evento', value: 'payment'),
            _DetailRow(
                label: 'ID do recurso',
                value: t.mpPaymentId?.toString() ?? '#${t.id}'),
            _DetailRow(label: 'Usuário', value: t.userName),
            _DetailRow(
                label: 'Valor',
                value:
                    '${t.chronosAmount} Chronos  •  R\$ ${t.totalAmount.toStringAsFixed(2)}'),
            _DetailRow(
                label: 'Método', value: t.isPix ? 'PIX' : 'Cartão de crédito'),
            _DetailRow(label: 'Data e hora', value: dateFormatted),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style:
                    const TextStyle(color: AppColors.cinza, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.branco,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
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
