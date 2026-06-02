import 'package:chronora/core/constants/app_routes.dart';
import 'package:chronora/core/constants/app_colors.dart';
import 'package:chronora/core/services/my_requests_service.dart';
import 'package:chronora/widgets/backgrounds/background_default_widget.dart';
import 'package:chronora/widgets/header.dart';
import 'package:chronora/widgets/service_card.dart';
import 'package:chronora/widgets/side_menu.dart';
import 'package:chronora/widgets/wallet_modal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MeusPedidosPage extends StatefulWidget {
  const MeusPedidosPage({super.key});

  @override
  State<MeusPedidosPage> createState() => _MeusPedidosPageState();
}

class _MeusPedidosPageState extends State<MeusPedidosPage> {
  static const Color _surfaceColor = Color(0xFF121414);
  static const Color _surfaceElevatedColor = Color(0xFF181A1A);
  static const Color _outlineColor = Color(0xFF2A2D2D);
  static const double _contentMaxWidth = 1240;

  static const List<String> _serviceStatuses = [
    'CRIADO',
    'ACEITO',
    'EM_ANDAMENTO',
    'CONCLUIDO',
    'CANCELADO',
  ];

  final TextEditingController _searchController = TextEditingController();
  final MyRequestsService _myRequestsService = MyRequestsService();

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isLoading = true;

  String _searchQuery = '';
  String _errorMessage = '';

  MyRequestsUserIdentity _currentUser = const MyRequestsUserIdentity(
    id: null,
    name: '',
    email: '',
  );
  String? _selectedSectionKey;
  List<ServiceEnvelope> _services = [];

  @override
  void initState() {
    super.initState();
    _loadMyRequests();
  }

  Future<void> _loadMyRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _myRequestsService.loadMyRequests();

      setState(() {
        _currentUser = result.currentUser;
        _services = result.services;
        _isLoading = false;
      });
      _logLoadSummary(result.stats);
    } on MyRequestsException catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Falha ao carregar seus pedidos: $error';
      });
    }
  }

  void _logLoadSummary(MyRequestsLoadStats stats) {
    if (!kDebugMode) {
      return;
    }

    final visibleCountsByStatus = <String, int>{
      for (final status in _serviceStatuses) status: 0,
    };
    var visibleForUser = 0;
    var createdByUser = 0;
    var acceptedByUser = 0;

    for (final envelope in _services) {
      final created = _isCreatedByCurrentUser(envelope);
      final accepted = _isAcceptedByCurrentUser(envelope);
      if (!created && !accepted) {
        continue;
      }

      visibleForUser++;
      if (created) {
        createdByUser++;
      }
      if (accepted) {
        acceptedByUser++;
      }

      final status = _normalizeStatus(envelope.service.status);
      visibleCountsByStatus[status] = (visibleCountsByStatus[status] ?? 0) + 1;
    }

    debugPrint(
      '[MeusPedidos] usuario='
      'id:${_currentUser.id ?? 'null'} '
      'nome:${_currentUser.name.isEmpty ? '<vazio>' : _currentUser.name} '
      'email:${_currentUser.email.isEmpty ? '<vazio>' : _currentUser.email} '
      'paginas:${stats.pagesFetched} '
      'itensApi:${stats.rawItemsFetched} '
      'unicosApi:${stats.uniqueServicesFetched} '
      'totalElements:${stats.totalElements ?? 'n/a'} '
      'visiveisUsuario:$visibleForUser '
      'criados:$createdByUser '
      'aceitos:$acceptedByUser '
      'status:$visibleCountsByStatus',
    );
  }

  List<_RequestSectionGroup> get _requestGroups {
    return [
      _RequestSectionGroup(
        key: 'created_by_me',
        title: 'Pedidos Criados por Voce',
        emptyMessage: _searchQuery.trim().isEmpty
            ? 'Nenhum pedido criado por voce foi encontrado.'
            : 'Nenhum pedido criado por voce combina com a busca.',
        requestsByStatus: _groupServicesByStatus(
          belongsToGroup: _isCreatedByCurrentUser,
        ),
      ),
      _RequestSectionGroup(
        key: 'accepted_from_others',
        title: 'Pedidos de Outros Usuarios Aceitos por Voce',
        emptyMessage: _searchQuery.trim().isEmpty
            ? 'Nenhum pedido de outro usuario aceito por voce foi encontrado.'
            : 'Nenhum pedido de outro usuario aceito por voce combina com a busca.',
        requestsByStatus: _groupServicesByStatus(
          belongsToGroup: (envelope) =>
              !_isCreatedByCurrentUser(envelope) &&
              _isAcceptedByCurrentUser(envelope),
        ),
      ),
    ];
  }

  Map<String, List<ServiceEnvelope>> _groupServicesByStatus({
    required bool Function(ServiceEnvelope envelope) belongsToGroup,
  }) {
    final grouped = <String, List<ServiceEnvelope>>{
      for (final status in _serviceStatuses) status: <ServiceEnvelope>[],
    };
    final merged = <int, ServiceEnvelope>{};

    for (final envelope in _services) {
      if (!belongsToGroup(envelope) || !_matchesSearch(envelope)) {
        continue;
      }

      merged[envelope.service.id] = envelope;
    }

    final ordered = merged.values.toList()
      ..sort((a, b) => b.service.id.compareTo(a.service.id));

    for (final envelope in ordered) {
      final status = _normalizeStatus(envelope.service.status);
      grouped.putIfAbsent(status, () => <ServiceEnvelope>[]).add(envelope);
    }

    return grouped;
  }

  bool _isCreatedByCurrentUser(ServiceEnvelope envelope) {
    final creator = envelope.service.userCreator;

    return _matchesCurrentUser(
      id: creator.id,
      name: creator.name,
      email: creator.email ?? '',
    );
  }

  bool _isAcceptedByCurrentUser(ServiceEnvelope envelope) {
    final accepted = envelope.service.userAccepted;
    if (accepted != null) {
      return _matchesCurrentUser(
        id: accepted.id,
        name: accepted.name,
        email: accepted.email ?? '',
      );
    }

    return _containsCurrentUserInAcceptedField(envelope.raw);
  }

  bool _containsCurrentUserInAcceptedField(dynamic node) {
    if (node is Map<String, dynamic>) {
      for (final entry in node.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value;

        if (_isAcceptedKey(key) && _valueContainsCurrentUser(value)) {
          return true;
        }

        if (!key.contains('creator') &&
            _containsCurrentUserInAcceptedField(value)) {
          return true;
        }
      }
    } else if (node is List) {
      for (final item in node) {
        if (_containsCurrentUserInAcceptedField(item)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isAcceptedKey(String key) {
    const hints = [
      'accept',
      'accepted',
      'assigned',
      'executor',
      'worker',
      'provider',
      'participant',
      'candidate',
      'applicant',
      'responsible',
      'helper',
      'volunteer',
      'seller',
      'buyer',
      'contracted',
    ];

    return hints.any(key.contains);
  }

  bool _valueContainsCurrentUser(dynamic value) {
    if (value is Map<String, dynamic>) {
      return _matchesCurrentUser(
        id: _toInt(value['id']),
        name: (value['name'] ?? '').toString(),
        email: (value['email'] ?? '').toString(),
      );
    }

    if (value is List) {
      return value.any(_valueContainsCurrentUser);
    }

    if (value is String) {
      final normalized = _normalizeText(value);
      return normalized.isNotEmpty &&
          (normalized == _normalizeText(_currentUser.name) ||
              normalized == _normalizeText(_currentUser.email));
    }

    if (value is int && _currentUser.id != null) {
      return value == _currentUser.id;
    }

    return false;
  }

  bool _matchesCurrentUser({int? id, String? name, String? email}) {
    final currentName = _normalizeText(_currentUser.name);
    final currentEmail = _normalizeText(_currentUser.email);

    if (_currentUser.id != null && id != null && _currentUser.id == id) {
      return true;
    }

    if (currentEmail.isNotEmpty &&
        _normalizeText(email ?? '') == currentEmail) {
      return true;
    }

    if (currentName.isNotEmpty && _normalizeText(name ?? '') == currentName) {
      return true;
    }

    return false;
  }

  bool _matchesSearch(ServiceEnvelope envelope) {
    final service = envelope.service;
    final query = _normalizeText(_searchQuery);

    return query.isEmpty ||
        _normalizeText(service.title).contains(query) ||
        _normalizeText(service.description).contains(query) ||
        _normalizeText(service.userCreator.name).contains(query) ||
        _normalizeText(service.userCreator.email ?? '').contains(query) ||
        service.categoryEntities.any(
          (category) => _normalizeText(category.name).contains(query),
        );
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _normalizeText(String value) => value.trim().toLowerCase();

  String _normalizeStatus(String value) {
    final normalized = value.trim().toUpperCase();
    if (_serviceStatuses.contains(normalized)) {
      return normalized;
    }

    return 'CRIADO';
  }

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _openWallet() {
    setState(() {
      _isDrawerOpen = false;
      _isWalletOpen = true;
    });
  }

  void _closeWallet() {
    setState(() {
      _isWalletOpen = false;
    });
  }

  void _toggleStatusSelection(String status) {
    setState(() {
      _selectedSectionKey = _selectedSectionKey == status ? null : status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final requestGroups = _requestGroups;

    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Stack(
        children: [
          Column(
            children: [
              Header(onMenuPressed: _toggleDrawer),
              Expanded(
                child: BackgroundDefaultWidget(
                  child: RefreshIndicator(
                    color: AppColors.amareloClaro,
                    onRefresh: _loadMyRequests,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _contentMaxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildPageHeader(requestGroups),
                              const SizedBox(height: 20),
                              _buildContent(requestGroups: requestGroups),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isDrawerOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: SideMenu(onWalletPressed: _openWallet),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleDrawer,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_isWalletOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: WalletModal(onClose: _closeWallet),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Buscar por titulo, categoria ou criador',
        hintStyle: TextStyle(color: AppColors.cinza.withValues(alpha: 0.78)),
        filled: true,
        fillColor: _surfaceElevatedColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _outlineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _outlineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.amareloClaro,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.amareloClaro),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.close, color: AppColors.cinza),
              ),
      ),
      cursorColor: AppColors.amareloClaro,
      style: const TextStyle(color: AppColors.branco),
    );
  }

  Widget _buildPageHeader(List<_RequestSectionGroup> requestGroups) {
    final totalRequests = requestGroups.fold<int>(
      0,
      (total, group) => total + group.totalServices,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;

          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Meus pedidos',
                style: TextStyle(
                  color: AppColors.branco,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$totalRequests pedido(s) vinculados ao seu login',
                style: TextStyle(
                  color: AppColors.cinza.withValues(alpha: 0.92),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );

          final search = isCompact
              ? _buildSearchField()
              : SizedBox(width: 430, child: _buildSearchField());

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading,
                const SizedBox(height: 18),
                search,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: heading),
              const SizedBox(width: 24),
              search,
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.amareloClaro.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.amareloClaro.withValues(alpha: 0.26),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.amareloClaro.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              color: AppColors.amareloClaro,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.branco,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.preto.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.branco.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amareloClaro.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: AppColors.amareloClaro,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              color: AppColors.branco.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _groupIcon(String groupKey) {
    switch (groupKey) {
      case 'created_by_me':
        return Icons.add_task_outlined;
      case 'accepted_from_others':
        return Icons.handshake_outlined;
      default:
        return Icons.list_alt_outlined;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'CRIADO':
        return Icons.pending_actions_outlined;
      case 'ACEITO':
        return Icons.check_circle_outline;
      case 'EM_ANDAMENTO':
        return Icons.timelapse_outlined;
      case 'CONCLUIDO':
        return Icons.task_alt_outlined;
      case 'CANCELADO':
        return Icons.cancel_outlined;
      default:
        return Icons.list_alt_outlined;
    }
  }

  String _statusActionLabel(bool isSelected) {
    return isSelected ? 'Ocultar pedidos' : 'Ver pedidos';
  }

  Widget _buildCountPill(int count, {bool isSelected = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44, minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.amareloClaro
            : AppColors.amareloClaro.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected
              ? AppColors.amareloClaro
              : AppColors.amareloClaro.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: isSelected ? AppColors.preto : AppColors.amareloClaro,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildContent({
    required List<_RequestSectionGroup> requestGroups,
  }) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildFeedbackText(_errorMessage);
    }

    if (_currentUser.name.isEmpty && _currentUser.email.isEmpty) {
      return _buildFeedbackText(
        'Nao foi possivel identificar o usuario logado para carregar seus pedidos.',
      );
    }

    final hasAnyServices =
        requestGroups.any((group) => group.totalServices > 0);
    if (!hasAnyServices) {
      return _buildFeedbackText(
        _searchQuery.trim().isEmpty
            ? 'Nenhum pedido relacionado ao seu login foi encontrado.'
            : 'Nenhum pedido combina com a busca.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < requestGroups.length; index++) ...[
          _buildRequestGroup(group: requestGroups[index]),
          if (index < requestGroups.length - 1) const SizedBox(height: 20),
        ],
        if (_selectedSectionKey == null)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _buildInfoBanner(
              'Selecione uma categoria de status para visualizar os pedidos.',
            ),
          ),
      ],
    );
  }

  Widget _buildRequestGroup({
    required _RequestSectionGroup group,
  }) {
    final availableStatuses = _availableStatuses(group.requestsByStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _outlineColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.amareloClaro.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.amareloClaro.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  _groupIcon(group.key),
                  color: AppColors.amareloClaro,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: const TextStyle(
                        color: AppColors.branco,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.totalServices} pedido(s)',
                      style: TextStyle(
                        color: AppColors.cinza.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCountPill(group.totalServices),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: AppColors.branco.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          if (availableStatuses.isEmpty)
            _buildEmptyState(group.emptyMessage)
          else
            Column(
              children: [
                for (var index = 0;
                    index < availableStatuses.length;
                    index++) ...[
                  _buildStatusSelectorItem(
                    sectionKey:
                        _buildSectionKey(group.key, availableStatuses[index]),
                    status: availableStatuses[index],
                    title: _statusSectionTitle(availableStatuses[index]),
                    services:
                        group.requestsByStatus[availableStatuses[index]] ??
                            const <ServiceEnvelope>[],
                  ),
                  if (index < availableStatuses.length - 1)
                    const SizedBox(height: 12),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusSelectorItem({
    required String sectionKey,
    required String status,
    required String title,
    required List<ServiceEnvelope> services,
  }) {
    final isSelected = _selectedSectionKey == sectionKey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.amareloClaro.withValues(alpha: 0.10)
            : _surfaceElevatedColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppColors.amareloClaro.withValues(alpha: 0.74)
              : _outlineColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _toggleStatusSelection(sectionKey),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.amareloClaro
                            : AppColors.branco.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.amareloClaro
                              : AppColors.branco.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        _statusIcon(status),
                        color: isSelected
                            ? AppColors.preto
                            : AppColors.amareloClaro,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.branco,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusActionLabel(isSelected),
                            style: TextStyle(
                              color: AppColors.cinza.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildCountPill(services.length, isSelected: isSelected),
                    const SizedBox(width: 12),
                    Icon(
                      isSelected
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: isSelected
                          ? AppColors.amareloClaro
                          : AppColors.branco,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSelected) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Divider(
                height: 1,
                thickness: 1,
                color: _outlineColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: _buildStatusSection(status: status, services: services),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSection({
    required String status,
    required List<ServiceEnvelope> services,
  }) {
    if (services.isEmpty) {
      return _buildEmptyState(
        _searchQuery.trim().isEmpty
            ? _emptyStatusMessage(status)
            : 'Nenhum pedido ${_statusDescription(status)} combina com a busca.',
      );
    }

    return _buildServiceList(services: services);
  }

  Widget _buildServiceList({
    required List<ServiceEnvelope> services,
  }) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final envelope = services[index];
        final navigationArguments = {
          'service': envelope.service,
          'readOnly': true,
          'showAcceptAction': false,
        };

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ServiceCard(
            service: envelope.service,
            onView: () async {
              final result = await Navigator.pushNamed(
                context,
                '${AppRoutes.requestView}/${envelope.service.id}',
                arguments: navigationArguments,
              );

              if (result == true) {
                await _loadMyRequests();
              }
            },
          ),
        );
      },
    );
  }

  String _statusSectionTitle(String status) {
    switch (status) {
      case 'CRIADO':
        return 'Pedidos Criados';
      case 'ACEITO':
        return 'Pedidos Aceitos';
      case 'EM_ANDAMENTO':
        return 'Pedidos em Andamento';
      case 'CONCLUIDO':
        return 'Pedidos Concluidos';
      case 'CANCELADO':
        return 'Pedidos Cancelados';
      default:
        return status;
    }
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'CRIADO':
        return 'criado';
      case 'ACEITO':
        return 'aceito';
      case 'EM_ANDAMENTO':
        return 'em andamento';
      case 'CONCLUIDO':
        return 'concluido';
      case 'CANCELADO':
        return 'cancelado';
      default:
        return status.toLowerCase();
    }
  }

  String _emptyStatusMessage(String status) {
    switch (status) {
      case 'CRIADO':
        return 'Nenhum pedido criado encontrado.';
      case 'ACEITO':
        return 'Nenhum pedido aceito encontrado.';
      case 'EM_ANDAMENTO':
        return 'Nenhum pedido em andamento encontrado.';
      case 'CONCLUIDO':
        return 'Nenhum pedido concluido encontrado.';
      case 'CANCELADO':
        return 'Nenhum pedido cancelado encontrado.';
      default:
        return 'Nenhum pedido encontrado.';
    }
  }

  Widget _buildFeedbackText(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.branco, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  List<String> _availableStatuses(
    Map<String, List<ServiceEnvelope>> requestsByStatus,
  ) {
    return _serviceStatuses
        .where((status) => (requestsByStatus[status] ?? const []).isNotEmpty)
        .toList();
  }

  String _buildSectionKey(String groupKey, String status) {
    return '$groupKey::$status';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _RequestSectionGroup {
  final String key;
  final String title;
  final String emptyMessage;
  final Map<String, List<ServiceEnvelope>> requestsByStatus;

  const _RequestSectionGroup({
    required this.key,
    required this.title,
    required this.emptyMessage,
    required this.requestsByStatus,
  });

  int get totalServices {
    return requestsByStatus.values.fold(
      0,
      (total, services) => total + services.length,
    );
  }
}
