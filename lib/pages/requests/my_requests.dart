import 'dart:async';

import 'package:chronora/core/constants/app_routes.dart';
import 'package:chronora/core/constants/app_colors.dart';
import 'package:chronora/core/services/my_requests_service.dart';
import 'package:chronora/widgets/backgrounds/background_default_widget.dart';
import 'package:chronora/widgets/header.dart';
import 'package:chronora/widgets/service_card.dart';
import 'package:chronora/widgets/animated_side_menu_overlay.dart';
import 'package:chronora/widgets/wallet_modal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'review_page.dart';

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
  static const int _sectionPageSize = 10;

  final TextEditingController _searchController = TextEditingController();
  final MyRequestsService _myRequestsService = MyRequestsService();

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isLoading = true;

  String _searchQuery = '';
  String _errorMessage = '';
  int _searchRevision = 0;

  MyRequestsUserIdentity _currentUser = const MyRequestsUserIdentity(
    id: null,
    name: '',
    email: '',
  );
  final List<ServiceEnvelope> _allServices = [];
  String? _selectedSectionKey;
  final Map<String, _LazyStatusSectionState> _statusSections = {};
  final Map<String, int> _sectionCounts = {};

  @override
  void initState() {
    super.initState();
    _loadMyRequests();
  }

  Future<void> _loadMyRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _selectedSectionKey = null;
      _allServices.clear();
      _statusSections.clear();
      _sectionCounts.clear();
    });

    try {
      final result = await _myRequestsService.loadMyRequests();

      setState(() {
        _currentUser = result.currentUser;
        _allServices
          ..clear()
          ..addAll(result.services);
        _sectionCounts.addAll(_buildSectionCounts(result.services));
        _isLoading = false;
      });
      _logIdentitySummary();
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

  void _logIdentitySummary() {
    if (!kDebugMode) {
      return;
    }

    debugPrint(
      '[MeusPedidos] usuario='
      'id:${_currentUser.id ?? 'null'} '
      'nome:${_currentUser.name.isEmpty ? '<vazio>' : _currentUser.name} '
      'email:${_currentUser.email.isEmpty ? '<vazio>' : _currentUser.email} '
      'modo:sob-demanda',
    );
  }

  List<_RequestSectionGroup> get _requestGroups {
    final sectionCounts = _currentSectionCounts;

    return [
      _RequestSectionGroup(
        key: 'created_by_me',
        title: 'Pedidos Criados por Voce',
        emptyMessage: _searchQuery.trim().isEmpty
            ? 'Nenhum pedido criado por voce foi encontrado.'
            : 'Nenhum pedido criado por voce combina com a busca.',
        countsByStatus: _countsByStatusForGroup(
          'created_by_me',
          sectionCounts,
        ),
        requestsByStatus: _groupServicesByStatus(
          groupKey: 'created_by_me',
          belongsToGroup: _isCreatedByCurrentUser,
        ),
      ),
      _RequestSectionGroup(
        key: 'accepted_from_others',
        title: 'Pedidos de Outros Usuarios Aceitos por Voce',
        emptyMessage: _searchQuery.trim().isEmpty
            ? 'Nenhum pedido de outro usuario aceito por voce foi encontrado.'
            : 'Nenhum pedido de outro usuario aceito por voce combina com a busca.',
        countsByStatus: _countsByStatusForGroup(
          'accepted_from_others',
          sectionCounts,
        ),
        requestsByStatus: _groupServicesByStatus(
          groupKey: 'accepted_from_others',
          belongsToGroup: (envelope) =>
              !_isCreatedByCurrentUser(envelope) &&
              _isAcceptedByCurrentUser(envelope),
        ),
      ),
    ];
  }

  Map<String, int> get _currentSectionCounts {
    if (_searchQuery.trim().isEmpty) {
      return _sectionCounts;
    }

    return _buildSectionCounts(
      _allServices.where(_matchesSearch).toList(),
    );
  }

  Map<String, int> _buildSectionCounts(List<ServiceEnvelope> services) {
    final counts = <String, int>{
      for (final groupKey in const [
        'created_by_me',
        'accepted_from_others',
      ])
        for (final status in _serviceStatuses)
          _buildSectionKey(groupKey, status): 0,
    };
    final seenBySection = <String, Set<int>>{};

    for (final envelope in services) {
      for (final groupKey in const [
        'created_by_me',
        'accepted_from_others',
      ]) {
        if (!_belongsToGroup(groupKey, envelope)) {
          continue;
        }

        final sectionKey = _buildSectionKey(
          groupKey,
          _normalizeStatus(envelope.service.status),
        );
        final seenIds = seenBySection.putIfAbsent(sectionKey, () => <int>{});
        if (seenIds.add(envelope.service.id)) {
          counts[sectionKey] = (counts[sectionKey] ?? 0) + 1;
        }
      }
    }

    return counts;
  }

  Map<String, int> _countsByStatusForGroup(
    String groupKey,
    Map<String, int> sectionCounts,
  ) {
    return <String, int>{
      for (final status in _serviceStatuses)
        status: sectionCounts[_buildSectionKey(groupKey, status)] ?? 0,
    };
  }

  Map<String, List<ServiceEnvelope>> _groupServicesByStatus({
    required String groupKey,
    required bool Function(ServiceEnvelope envelope) belongsToGroup,
  }) {
    final grouped = <String, List<ServiceEnvelope>>{
      for (final status in _serviceStatuses) status: <ServiceEnvelope>[],
    };

    for (final status in _serviceStatuses) {
      final sectionKey = _buildSectionKey(groupKey, status);
      final state = _statusSections[sectionKey];
      if (state == null) {
        continue;
      }

      final merged = <int, ServiceEnvelope>{};
      for (final envelope in state.services) {
        if (_normalizeStatus(envelope.service.status) != status ||
            !belongsToGroup(envelope) ||
            !_matchesSearch(envelope)) {
          continue;
        }

        merged[envelope.service.id] = envelope;
      }

      grouped[status] = merged.values.toList()
        ..sort((a, b) => b.service.id.compareTo(a.service.id));
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
    return _matchesSearchQuery(envelope, _searchQuery);
  }

  bool _matchesSearchQuery(ServiceEnvelope envelope, String searchQuery) {
    final service = envelope.service;
    final query = _normalizeText(searchQuery);

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

  void _handleSearchChanged(String value) {
    if (value == _searchQuery) {
      return;
    }

    final selectedSectionKey = _selectedSectionKey;

    setState(() {
      _searchQuery = value;
      _searchRevision++;
      _statusSections.clear();
    });

    if (selectedSectionKey != null) {
      final parsedSectionKey = _parseSectionKey(selectedSectionKey);
      if (parsedSectionKey != null) {
        unawaited(
          _loadStatusSection(
            sectionKey: selectedSectionKey,
            groupKey: parsedSectionKey.groupKey,
            status: parsedSectionKey.status,
            reset: true,
          ),
        );
      }
    }
  }

  _ParsedSectionKey? _parseSectionKey(String sectionKey) {
    final separatorIndex = sectionKey.indexOf('::');
    if (separatorIndex <= 0 || separatorIndex >= sectionKey.length - 2) {
      return null;
    }

    return _ParsedSectionKey(
      groupKey: sectionKey.substring(0, separatorIndex),
      status: sectionKey.substring(separatorIndex + 2),
    );
  }

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

  Future<void> _toggleStatusSelection({
    required String sectionKey,
    required String groupKey,
    required String status,
  }) async {
    final shouldSelect = _selectedSectionKey != sectionKey;
    setState(() {
      _selectedSectionKey = shouldSelect ? sectionKey : null;
    });

    if (!shouldSelect) {
      return;
    }

    final state = _sectionState(sectionKey);
    if (!state.hasLoaded) {
      await _loadStatusSection(
        sectionKey: sectionKey,
        groupKey: groupKey,
        status: status,
        reset: true,
      );
    }
  }

  _LazyStatusSectionState _sectionState(String sectionKey) {
    return _statusSections.putIfAbsent(
      sectionKey,
      _LazyStatusSectionState.new,
    );
  }

  Future<void> _loadStatusSection({
    required String sectionKey,
    required String groupKey,
    required String status,
    bool reset = false,
  }) async {
    final state = _sectionState(sectionKey);
    if (state.isLoading || (!reset && !state.hasMore)) {
      return;
    }

    setState(() {
      state.isLoading = true;
      state.errorMessage = '';
      if (reset) {
        state.services.clear();
        state.nextPage = 0;
        state.hasMore = true;
        state.hasLoaded = false;
      }
    });

    try {
      var page = state.nextPage;
      var hasMore = state.hasMore;
      final fetched = <ServiceEnvelope>[];
      final seenIds = state.services.map((item) => item.service.id).toSet();
      final searchQuery = _searchQuery;
      final searchRevision = _searchRevision;
      final isSearching = searchQuery.trim().isNotEmpty;
      var matchingFetched = 0;

      while (
          (isSearching ? matchingFetched : fetched.length) < _sectionPageSize &&
              hasMore) {
        final result = await _myRequestsService.loadStatusPage(
          status: status,
          page: page,
          pageSize: _sectionPageSize,
        );

        for (final envelope in result.services) {
          if (!_belongsToGroup(groupKey, envelope)) {
            continue;
          }
          if (seenIds.add(envelope.service.id)) {
            fetched.add(envelope);
            if (_matchesSearchQuery(envelope, searchQuery)) {
              matchingFetched++;
            }
          }
        }

        hasMore = result.hasMore;
        page = result.page + 1;

        if (result.services.isEmpty) {
          break;
        }
      }

      if (!mounted || searchRevision != _searchRevision) return;
      setState(() {
        state.services.addAll(fetched);
        state.services.sort((a, b) => b.service.id.compareTo(a.service.id));
        state.nextPage = page;
        state.hasMore = hasMore;
        state.hasLoaded = true;
        state.isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        state.errorMessage = 'Falha ao carregar pedidos: $error';
        state.hasLoaded = true;
        state.isLoading = false;
      });
    }
  }

  bool _belongsToGroup(String groupKey, ServiceEnvelope envelope) {
    switch (groupKey) {
      case 'created_by_me':
        return _isCreatedByCurrentUser(envelope);
      case 'accepted_from_others':
        return !_isCreatedByCurrentUser(envelope) &&
            _isAcceptedByCurrentUser(envelope);
      default:
        return false;
    }
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
          AnimatedSideMenuOverlay(
            isOpen: _isDrawerOpen,
            onClose: _toggleDrawer,
            onWalletPressed: _openWallet,
            top: 0,
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
      onChanged: _handleSearchChanged,
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
                  _handleSearchChanged('');
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
    final availableStatuses = _availableStatuses(group.key);

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
                    groupKey: group.key,
                    sectionKey:
                        _buildSectionKey(group.key, availableStatuses[index]),
                    status: availableStatuses[index],
                    title: _statusSectionTitle(availableStatuses[index]),
                    totalCount:
                        group.countsByStatus[availableStatuses[index]] ?? 0,
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
    required String groupKey,
    required String sectionKey,
    required String status,
    required String title,
    required int totalCount,
    required List<ServiceEnvelope> services,
  }) {
    final isSelected = _selectedSectionKey == sectionKey;

    return AnimatedContainer(
      key: ValueKey('my-requests-status-$sectionKey'),
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
              onTap: () => _toggleStatusSelection(
                sectionKey: sectionKey,
                groupKey: groupKey,
                status: status,
              ),
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
                    _buildCountPill(totalCount, isSelected: isSelected),
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
              child: _buildStatusSection(
                sectionKey: sectionKey,
                groupKey: groupKey,
                status: status,
                totalCount: totalCount,
                services: services,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusSection({
    required String sectionKey,
    required String groupKey,
    required String status,
    required int totalCount,
    required List<ServiceEnvelope> services,
  }) {
    final state = _statusSections[sectionKey];

    if (state != null && state.isLoading && services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
          ),
        ),
      );
    }

    if (state != null && state.errorMessage.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFeedbackText(state.errorMessage),
          const SizedBox(height: 12),
          _buildSectionLoadMoreButton(
            label: 'Tentar novamente',
            onPressed: () => _loadStatusSection(
              sectionKey: sectionKey,
              groupKey: groupKey,
              status: status,
            ),
          ),
        ],
      );
    }

    if (services.isEmpty) {
      return _buildEmptyState(
        state == null || !state.hasLoaded
            ? 'Abra esta categoria para carregar os pedidos.'
            : _searchQuery.trim().isEmpty
                ? _emptyStatusMessage(status)
                : 'Nenhum pedido ${_statusDescription(status)} combina com a busca.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildServiceList(
          services: services,
          groupKey: groupKey,
          status: status,
        ),
        if (state != null && state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
              ),
            ),
          )
        else if (state != null && state.hasMore && services.length < totalCount)
          _buildSectionLoadMoreButton(
            label: 'Carregar mais',
            onPressed: () => _loadStatusSection(
              sectionKey: sectionKey,
              groupKey: groupKey,
              status: status,
            ),
          ),
      ],
    );
  }

  Widget _buildServiceList({
    required List<ServiceEnvelope> services,
    required String groupKey,
    required String status,
  }) {
    final isProvider = groupKey == 'accepted_from_others';

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final envelope = services[index];
        final service = envelope.service;
        final navigationArguments = {
          'service': service,
          'readOnly': true,
          'showAcceptAction': false,
        };

        final showReview = status == 'CONCLUIDO' &&
            (isProvider ? !service.ratedByProvider : !service.ratedByCreator);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ServiceCard(
                service: service,
                onView: () async {
                  if (status == 'EM_ANDAMENTO') {
                    await Navigator.pushNamed(
                      context,
                      AppRoutes.orderInProgress,
                      arguments: {'serviceId': service.id},
                    );
                    await _loadMyRequests();
                    return;
                  }

                  final result = await Navigator.pushNamed(
                    context,
                    '${AppRoutes.requestView}/${service.id}',
                    arguments: navigationArguments,
                  );

                  if (result == true) {
                    await _loadMyRequests();
                  }
                },
              ),
              if (showReview) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewPage(
                            serviceId: service.id,
                            isProvider: isProvider,
                          ),
                        ),
                      );
                      await _loadMyRequests();
                    },
                    icon: const Icon(Icons.star_outline, size: 18),
                    label: Text(
                      isProvider ? 'Avaliar solicitante' : 'Avaliar prestador',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloUmPoucoEscuro,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
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

  Widget _buildSectionLoadMoreButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amareloClaro,
          foregroundColor: AppColors.preto,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  List<String> _availableStatuses(String groupKey) {
    if (groupKey == 'accepted_from_others') {
      return _serviceStatuses.where((status) => status != 'CRIADO').toList();
    }

    return _serviceStatuses;
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
  final Map<String, int> countsByStatus;
  final Map<String, List<ServiceEnvelope>> requestsByStatus;

  const _RequestSectionGroup({
    required this.key,
    required this.title,
    required this.emptyMessage,
    required this.countsByStatus,
    required this.requestsByStatus,
  });

  int get totalServices {
    return countsByStatus.values.fold(
      0,
      (total, count) => total + count,
    );
  }
}

class _LazyStatusSectionState {
  final List<ServiceEnvelope> services = [];
  int nextPage = 0;
  bool hasMore = true;
  bool isLoading = false;
  bool hasLoaded = false;
  String errorMessage = '';
}

class _ParsedSectionKey {
  final String groupKey;
  final String status;

  const _ParsedSectionKey({
    required this.groupKey,
    required this.status,
  });
}
