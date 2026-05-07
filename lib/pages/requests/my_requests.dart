import 'dart:convert';

import 'package:chronora/core/constants/app_routes.dart';
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
  String? _selectedStatus;
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

  Map<String, List<ServiceEnvelope>> get _requestsByStatus {
    final grouped = <String, List<ServiceEnvelope>>{
      for (final status in _serviceStatuses) status: <ServiceEnvelope>[],
    };
    final merged = <int, ServiceEnvelope>{};

    for (final envelope in _services) {
      final belongsToCurrentUser = _isCreatedByCurrentUser(envelope) ||
          _isAcceptedByCurrentUser(envelope);

      if (!belongsToCurrentUser || !_matchesSearch(envelope)) {
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
      _selectedStatus = _selectedStatus == status ? null : status;
    });
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
                      child: SafeArea(
                        top: true,
                        bottom: false,
                        child: SideMenu(onWalletPressed: _openWallet),
                      ),
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
        'Nao foi possivel identificar o usuario logado para carregar seus pedidos.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusSelector(requestsByStatus: requestsByStatus),
        if (_selectedStatus == null)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              'Selecione um status para visualizar os pedidos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.branco,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusSelector({
    required Map<String, List<ServiceEnvelope>> requestsByStatus,
  }) {
    return Column(
      children: [
        for (var index = 0; index < _serviceStatuses.length; index++) ...[
          _buildStatusSelectorItem(
            status: _serviceStatuses[index],
            title: _statusSectionTitle(_serviceStatuses[index]),
            services: requestsByStatus[_serviceStatuses[index]] ??
                const <ServiceEnvelope>[],
          ),
          if (index < _serviceStatuses.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildStatusSelectorItem({
    required String status,
    required String title,
    required List<ServiceEnvelope> services,
  }) {
    final isSelected = _selectedStatus == status;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.branco.withValues(alpha: 0.10)
            : AppColors.branco.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppColors.amareloClaro
              : AppColors.branco.withValues(alpha: 0.16),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _toggleStatusSelection(status),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.branco,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSelected
                                ? 'Toque para ocultar os pedidos'
                                : 'Toque para visualizar os pedidos',
                            style: TextStyle(
                              color: AppColors.branco.withValues(alpha: 0.78),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.amareloClaro
                            : AppColors.amareloUmPoucoEscuro.withValues(
                                alpha: 0.32,
                              ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${services.length}',
                        style: TextStyle(
                          color:
                              isSelected ? AppColors.preto : AppColors.branco,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
                color: AppColors.amareloUmPoucoEscuro,
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
      return _buildFeedbackText(
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
        final canEdit = _isCreatedByCurrentUser(envelope);
        final navigationArguments = {
          'service': envelope.service,
          'readOnly': !canEdit,
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
            onEdit: canEdit
                ? () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRoutes.requestEditing,
                      arguments: navigationArguments,
                    );

                    if (result == true) {
                      await _loadMyRequests();
                    }
                  }
                : null,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}



