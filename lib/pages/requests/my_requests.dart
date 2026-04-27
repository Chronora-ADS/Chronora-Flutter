import 'dart:convert';

import 'package:chronora/core/constants/app_colors.dart';
import 'package:chronora/core/models/main_page_requests_model.dart';
import 'package:chronora/core/services/api_service.dart';
import 'package:chronora/widgets/backgrounds/background_default_widget.dart';
import 'package:chronora/widgets/header.dart';
import 'package:chronora/widgets/service_card.dart';
import 'package:chronora/widgets/side_menu.dart';
import 'package:chronora/widgets/wallet_modal.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OrdenacaoTipo {
  maisRecentes,
  maisAntigos,
  maiorAvaliacao,
  maiorChronos,
  menorChronos,
}

class UserIdentity {
  final int? id;
  final String name;
  final String email;

  const UserIdentity({
    required this.id,
    required this.name,
    required this.email,
  });
}

class RequestFilterState {
  final double minRating;
  final int? minChronos;
  final int? maxChronos;
  final String? category;
  final String? modality;
  final OrdenacaoTipo ordenacao;

  const RequestFilterState({
    this.minRating = 0,
    this.minChronos,
    this.maxChronos,
    this.category,
    this.modality,
    this.ordenacao = OrdenacaoTipo.maisRecentes,
  });

  RequestFilterState copyWith({
    double? minRating,
    int? minChronos,
    int? maxChronos,
    String? category,
    bool clearCategory = false,
    String? modality,
    bool clearModality = false,
    OrdenacaoTipo? ordenacao,
  }) {
    return RequestFilterState(
      minRating: minRating ?? this.minRating,
      minChronos: minChronos ?? this.minChronos,
      maxChronos: maxChronos ?? this.maxChronos,
      category: clearCategory ? null : (category ?? this.category),
      modality: clearModality ? null : (modality ?? this.modality),
      ordenacao: ordenacao ?? this.ordenacao,
    );
  }

  bool get isActive {
    return minRating > 0 ||
        minChronos != null ||
        maxChronos != null ||
        category != null ||
        modality != null ||
        ordenacao != OrdenacaoTipo.maisRecentes;
  }
}

class ServiceEnvelope {
  final Service service;
  final Map<String, dynamic> raw;

  const ServiceEnvelope({
    required this.service,
    required this.raw,
  });
}

class MeusPedidosPage extends StatefulWidget {
  const MeusPedidosPage({super.key});

  @override
  State<MeusPedidosPage> createState() => _MeusPedidosPageState();
}

class _MeusPedidosPageState extends State<MeusPedidosPage> {
  static const List<String> _serviceStatuses = [
    'CRIADO',
    'ACEITO',
    'EM_ANDAMENTO',
    'CONCLUIDO',
    'CANCELADO',
  ];

  final TextEditingController _searchController = TextEditingController();

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isLoading = true;

  String _searchQuery = '';
  String _errorMessage = '';

  UserIdentity _currentUser = const UserIdentity(id: null, name: '', email: '');
  RequestFilterState _filters = const RequestFilterState();
  List<ServiceEnvelope> _services = [];

  @override
  void initState() {
    super.initState();
    _loadMyRequests();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _loadMyRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await _getToken();

      if (token == null) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Você precisa estar logado para visualizar seus pedidos.';
        });
        return;
      }

      final decodedUser = _extractUserFromToken(token);
      final servicesResponse = await ApiService.get(
        '/service/get/all',
        token: token,
      );

      if (servicesResponse.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Erro ${servicesResponse.statusCode} ao carregar seus pedidos.';
        });
        return;
      }

      setState(() {
        _currentUser = decodedUser;
        _services = _parseServicesResponse(servicesResponse.body);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Falha ao carregar seus pedidos: $error';
      });
    }
  }

  UserIdentity _extractCurrentUser(String responseBody) {
    try {
      final data = json.decode(responseBody);
      if (data is Map<String, dynamic>) {
        return UserIdentity(
          id: _toInt(data['id']),
          name: (data['name'] ?? '').toString().trim(),
          email: (data['email'] ?? '').toString().trim(),
        );
      }
    } catch (_) {}

    return const UserIdentity(id: null, name: '', email: '');
  }

  UserIdentity _extractUserFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        return const UserIdentity(id: null, name: '', email: '');
      }

      final normalizedPayload = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalizedPayload));
      final data = json.decode(payload);

      if (data is! Map<String, dynamic>) {
        return const UserIdentity(id: null, name: '', email: '');
      }

      return UserIdentity(
        id: _extractIdFromTokenClaims(data),
        name: _extractStringFromMap(data, const [
          'name',
          'unique_name',
          'preferred_username',
          'user_name',
        ]),
        email: _extractStringFromMap(data, const [
          'email',
          'sub',
          'upn',
          'preferred_username',
        ]),
      );
    } catch (_) {
      return const UserIdentity(id: null, name: '', email: '');
    }
  }

  int? _extractIdFromTokenClaims(Map<String, dynamic> data) {
    for (final key in const ['id', 'userId', 'user_id']) {
      final value = _toInt(data[key]);
      if (value != null) {
        return value;
      }
    }

    return null;
  }

  String _extractStringFromMap(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  List<ServiceEnvelope> _parseServicesResponse(String responseBody) {
    final responseData = json.decode(responseBody);
    List<dynamic> items = [];

    if (responseData is Map<String, dynamic>) {
      if (responseData['services'] is List) {
        items = responseData['services'] as List<dynamic>;
      } else if (responseData['data'] is List) {
        items = responseData['data'] as List<dynamic>;
      } else if (responseData['content'] is List) {
        items = responseData['content'] as List<dynamic>;
      }
    } else if (responseData is List<dynamic>) {
      items = responseData;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => ServiceEnvelope(
            service: Service.fromJson(item),
            raw: item,
          ),
        )
        .toList();
  }

  List<String> get _availableCategories {
    final categories = <String>{};

    for (final envelope in _services) {
      for (final category in envelope.service.categoryEntities) {
        final name = category.name.trim();
        if (name.isNotEmpty) {
          categories.add(name);
        }
      }
    }

    final values = categories.toList()..sort();
    return values;
  }

  Map<String, List<ServiceEnvelope>> get _requestsByStatus {
    final grouped = <String, List<ServiceEnvelope>>{
      for (final status in _serviceStatuses) status: <ServiceEnvelope>[],
    };
    final merged = <int, ServiceEnvelope>{};

    for (final envelope in _services) {
      final belongsToCurrentUser =
          _isCreatedByCurrentUser(envelope) || _isAcceptedByCurrentUser(envelope);

      if (!belongsToCurrentUser || !_matchesFilters(envelope)) {
        continue;
      }

      merged[envelope.service.id] = envelope;
    }

    final ordered = merged.values.toList()..sort(_compareServices);

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

        if (!key.contains('creator') && _containsCurrentUserInAcceptedField(value)) {
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

    if (currentEmail.isNotEmpty && _normalizeText(email ?? '') == currentEmail) {
      return true;
    }

    if (currentName.isNotEmpty && _normalizeText(name ?? '') == currentName) {
      return true;
    }

    return false;
  }

  bool _matchesFilters(ServiceEnvelope envelope) {
    final service = envelope.service;
    final query = _normalizeText(_searchQuery);

    final matchesSearch = query.isEmpty ||
        _normalizeText(service.title).contains(query) ||
        _normalizeText(service.userCreator.name).contains(query) ||
        service.categoryEntities.any(
          (category) => _normalizeText(category.name).contains(query),
        );

    final matchesRating = _extractUserRating(envelope.raw) >= _filters.minRating;
    final matchesChronos =
        (_filters.minChronos == null ||
            service.timeChronos >= _filters.minChronos!) &&
        (_filters.maxChronos == null ||
            service.timeChronos <= _filters.maxChronos!);
    final matchesCategory = _filters.category == null ||
        service.categoryEntities.any(
          (category) =>
              _normalizeText(category.name) ==
              _normalizeText(_filters.category!),
        );
    final matchesModality = _filters.modality == null ||
        _normalizeText(service.modality) ==
            _normalizeText(_filters.modality!);

    return matchesSearch &&
        matchesRating &&
        matchesChronos &&
        matchesCategory &&
        matchesModality;
  }

  int _compareServices(ServiceEnvelope a, ServiceEnvelope b) {
    switch (_filters.ordenacao) {
      case OrdenacaoTipo.maisRecentes:
        return b.service.id.compareTo(a.service.id);
      case OrdenacaoTipo.maisAntigos:
        return a.service.id.compareTo(b.service.id);
      case OrdenacaoTipo.maiorAvaliacao:
        return _extractUserRating(b.raw).compareTo(_extractUserRating(a.raw));
      case OrdenacaoTipo.maiorChronos:
        return b.service.timeChronos.compareTo(a.service.timeChronos);
      case OrdenacaoTipo.menorChronos:
        return a.service.timeChronos.compareTo(b.service.timeChronos);
    }
  }

  double _extractUserRating(Map<String, dynamic> raw) {
    final values = <double>[];

    void collect(dynamic node, {String key = ''}) {
      if (node is Map<String, dynamic>) {
        for (final entry in node.entries) {
          collect(entry.value, key: entry.key.toLowerCase());
        }
        return;
      }

      if (node is List) {
        for (final item in node) {
          collect(item, key: key);
        }
        return;
      }

      if (key.contains('rating') || key.contains('avali')) {
        final value = _toDouble(node);
        if (value != null) {
          values.add(value);
        }
      }
    }

    collect(raw['userCreator'], key: 'usercreator');
    collect(raw);

    return values.isEmpty ? 0 : values.first;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
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

  Future<void> _showFiltersModal() async {
    final newFilters = await showModalBottomSheet<RequestFilterState>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestFiltersModal(
        initialFilters: _filters,
        availableCategories: _availableCategories,
      ),
    );

    if (newFilters != null) {
      setState(() {
        _filters = newFilters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsByStatus = _requestsByStatus;

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
                      padding: const EdgeInsets.only(
                        top: 16,
                        left: 16,
                        right: 16,
                        bottom: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchField(),
                          const SizedBox(height: 24),
                          _buildSeparators(),
                          const SizedBox(height: 24),
                          _buildFiltersButton(),
                          const SizedBox(height: 24),
                          _buildContent(requestsByStatus: requestsByStatus),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_isDrawerOpen)
            Positioned(
              top: kToolbarHeight * 1.5,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
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
                color: Colors.black.withOpacity(0.5),
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
        hintText: 'Pintura de parede, aula de inglês...',
        hintStyle: const TextStyle(color: AppColors.textoPlaceholder),
        filled: true,
        fillColor: AppColors.branco,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textoPlaceholder,
        ),
      ),
    );
  }

  Widget _buildSeparators() {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: 3,
            color: AppColors.branco,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.center,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 3,
            color: AppColors.branco,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _showFiltersModal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.branco,
          foregroundColor: AppColors.preto,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _filters.isActive ? 'Filtros aplicados' : 'Filtros',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required Map<String, List<ServiceEnvelope>> requestsByStatus,
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
        'Não foi possível identificar o usuário logado para filtrar seus pedidos.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < _serviceStatuses.length; index++) ...[
          _buildSectionTitle(_statusSectionTitle(_serviceStatuses[index])),
          const SizedBox(height: 12),
          _buildStatusSection(
            status: _serviceStatuses[index],
            services:
                requestsByStatus[_serviceStatuses[index]] ??
                const <ServiceEnvelope>[],
          ),
          if (index < _serviceStatuses.length - 1) _buildYellowSeparator(),
        ],
      ],
    );
  }

  Widget _buildStatusSection({
    required String status,
    required List<ServiceEnvelope> services,
  }) {
    if (services.isEmpty) {
      return _buildFeedbackText(
        _searchQuery.trim().isEmpty && !_filters.isActive
            ? _emptyStatusMessage(status)
            : 'Nenhum pedido ${_statusDescription(status)} combina com os filtros.',
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
        final canEdit = _isCreatedByCurrentUser(envelope);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ServiceCard(
            service: envelope.service,
            enableNavigation: canEdit,
            onEdit: canEdit
                ? () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/request-editing',
                      arguments: envelope.service,
                    );

                    if (result == true) {
                      await _loadMyRequests();
                    }
                  }
                : null,
            onCardEdited: canEdit
                ? (edited) async {
                    if (edited) {
                      await _loadMyRequests();
                    }
                  }
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.branco,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildYellowSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 3,
        color: AppColors.amareloUmPoucoEscuro,
      ),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _RequestFiltersModal extends StatefulWidget {
  final RequestFilterState initialFilters;
  final List<String> availableCategories;

  const _RequestFiltersModal({
    required this.initialFilters,
    required this.availableCategories,
  });

  @override
  State<_RequestFiltersModal> createState() => _RequestFiltersModalState();
}

class _RequestFiltersModalState extends State<_RequestFiltersModal> {
  static const List<_ChronosRangeOption> _chronosOptions = [
    _ChronosRangeOption(label: 'Todos', min: null, max: null),
    _ChronosRangeOption(label: '1-5 Chronos', min: 1, max: 5),
    _ChronosRangeOption(label: '6-10 Chronos', min: 6, max: 10),
    _ChronosRangeOption(label: '11-20 Chronos', min: 11, max: 20),
    _ChronosRangeOption(label: '21-50 Chronos', min: 21, max: 50),
    _ChronosRangeOption(label: '51+ Chronos', min: 51, max: null),
  ];

  late RequestFilterState _draftFilters;

  @override
  void initState() {
    super.initState();
    _draftFilters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Center(
                  child: Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppColors.preto,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 32),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Avaliação do usuário'),
                  _buildDropdown<double>(
                    value: _draftFilters.minRating,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Todas')),
                      DropdownMenuItem(value: 3, child: Text('> 3 estrelas')),
                      DropdownMenuItem(value: 4, child: Text('> 4 estrelas')),
                      DropdownMenuItem(value: 4.5, child: Text('> 4.5 estrelas')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _draftFilters = _draftFilters.copyWith(
                          minRating: value ?? 0,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Tempo'),
                  _buildDropdown<_ChronosRangeOption>(
                    value: _selectedChronosOption(),
                    items: _chronosOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _draftFilters = _draftFilters.copyWith(
                          minChronos: value.min,
                          maxChronos: value.max,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Categorias'),
                  _buildDropdown<String?>(
                    value: _draftFilters.category,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...widget.availableCategories.map(
                        (category) => DropdownMenuItem<String?>(
                          value: category,
                          child: Text(category),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _draftFilters = _draftFilters.copyWith(
                          category: value,
                          clearCategory: value == null,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Modalidade'),
                  _buildDropdown<String?>(
                    value: _draftFilters.modality,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Presencial',
                        child: Text('Presencial'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'À distância',
                        child: Text('À distância'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Remoto',
                        child: Text('Remoto'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'Híbrido',
                        child: Text('Híbrido'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _draftFilters = _draftFilters.copyWith(
                          modality: value,
                          clearModality: value == null,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Ordenação'),
                  _buildDropdown<OrdenacaoTipo>(
                    value: _draftFilters.ordenacao,
                    items: const [
                      DropdownMenuItem(
                        value: OrdenacaoTipo.maisRecentes,
                        child: Text('Mais recentes'),
                      ),
                      DropdownMenuItem(
                        value: OrdenacaoTipo.maisAntigos,
                        child: Text('Mais antigos'),
                      ),
                      DropdownMenuItem(
                        value: OrdenacaoTipo.maiorAvaliacao,
                        child: Text('Melhores avaliados'),
                      ),
                      DropdownMenuItem(
                        value: OrdenacaoTipo.maiorChronos,
                        child: Text('Maior tempo'),
                      ),
                      DropdownMenuItem(
                        value: OrdenacaoTipo.menorChronos,
                        child: Text('Menor tempo'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _draftFilters = _draftFilters.copyWith(
                          ordenacao: value,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _draftFilters = const RequestFilterState();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.amareloUmPoucoEscuro,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Limpar filtros',
                        style: TextStyle(
                          color: AppColors.amareloUmPoucoEscuro,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _draftFilters),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloUmPoucoEscuro,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Aplicar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.branco,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ChronosRangeOption _selectedChronosOption() {
    return _chronosOptions.firstWhere(
      (option) =>
          option.min == _draftFilters.minChronos &&
          option.max == _draftFilters.maxChronos,
      orElse: () => _chronosOptions.first,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.preto,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.branco,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.brancoBorda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.brancoBorda),
        ),
      ),
      icon: const Icon(Icons.keyboard_arrow_down),
    );
  }
}

class _ChronosRangeOption {
  final String label;
  final int? min;
  final int? max;

  const _ChronosRangeOption({
    required this.label,
    required this.min,
    required this.max,
  });
}
