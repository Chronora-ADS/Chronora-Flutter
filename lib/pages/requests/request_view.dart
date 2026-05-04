import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/main_page_requests_model.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/services/auth_session_service.dart';
import '../../widgets/backgrounds/background_default_widget.dart';
import '../../widgets/header.dart';
import '../../widgets/service_image.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';

class RequestView extends StatefulWidget {
  final int? serviceId;
  final Service? service;

  const RequestView({
    super.key,
    this.serviceId,
    this.service,
  });

  @override
  State<RequestView> createState() => _RequestViewState();
}

class _RequestViewState extends State<RequestView> {
  ServiceDetailModel? _serviceDetail;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOwner = false;
  bool _showAcceptAction = true;
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  int _walletRefreshVersion = 0;
  bool _resolvedRouteArguments = false;

  @override
  void initState() {
    super.initState();
    final serviceId = widget.serviceId ?? widget.service?.id;
    if (serviceId != null) {
      _loadData(serviceId);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolvedRouteArguments) {
      return;
    }

    _resolvedRouteArguments = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    _applyRouteOptions(arguments);

    if (widget.serviceId != null || widget.service != null) {
      return;
    }

    final serviceId = _resolveServiceIdFromArguments(arguments);

    if (serviceId == null) {
      setState(() {
        _errorMessage = 'ID do servico nao informado.';
        _isLoading = false;
      });
      return;
    }

    _loadData(serviceId);
  }

  int? _resolveServiceIdFromArguments(dynamic arguments) {
    if (arguments is int) return arguments;
    if (arguments is Service) return arguments.id;
    if (arguments is Map) {
      if (arguments['serviceId'] is int) {
        return arguments['serviceId'] as int;
      }
      if (arguments['service'] is Service) {
        return (arguments['service'] as Service).id;
      }
    }
    return null;
  }

  void _applyRouteOptions(dynamic arguments) {
    if (arguments is Map && arguments['showAcceptAction'] is bool) {
      _showAcceptAction = arguments['showAcceptAction'] as bool;
    }
  }

  Future<void> _loadData(int serviceId) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) {
        throw Exception('Usuario nao autenticado.');
      }

      final currentUserId = await _fetchCurrentUserId(token);
      final response =
          await ApiService.get('/service/get/$serviceId', token: token);
      if (response.statusCode != 200) {
        throw Exception(
          ApiService.extractErrorMessage(
            response.body,
            fallback: 'Nao foi possivel carregar o pedido.',
          ),
        );
      }

      final detail = ServiceDetailModel.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      if (!mounted) return;
      setState(() {
        _serviceDetail = detail;
        _isOwner = detail.userCreator.id == currentUserId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<int?> _fetchCurrentUserId(String token) async {
    try {
      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final value = decoded['id'] ?? decoded['data']?['id'];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value);
      }
    } catch (_) {
      // Ignore owner lookup errors and keep the page usable.
    }

    return null;
  }

  Future<void> _cancelRequest() async {
    final detail = _serviceDetail;
    if (detail?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancelar pedido'),
          content: const Text('Deseja cancelar este pedido?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nao'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) {
        throw Exception('Usuario nao autenticado.');
      }

      final response = await ApiService.delete(
        '/service/cancelService/${detail!.id}',
        token: token,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          ApiService.extractErrorMessage(
            response.body,
            fallback: 'Nao foi possivel cancelar o pedido.',
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado com sucesso.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _editRequest() {
    final detail = _serviceDetail;
    if (detail?.id == null) return;

    Navigator.pushNamed(
      context,
      AppRoutes.requestEditingWithId(detail!.id!),
    ).then((edited) {
      if (edited == true && mounted) {
        setState(() {
          _walletRefreshVersion++;
        });
        _loadData(detail.id!);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Stack(
        children: [
          Column(
            children: [
              Header(
                key: ValueKey(_walletRefreshVersion),
                onMenuPressed: _toggleDrawer,
              ),
              Expanded(
                child: BackgroundDefaultWidget(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: _buildContent(),
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
                      width: screenWidth * 0.6,
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

  Widget _buildContent() {
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

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.branco, fontSize: 16),
        ),
      );
    }

    final detail = _serviceDetail;
    if (detail == null) {
      return const Center(
        child: Text(
          'Detalhes do pedido indisponiveis.',
          style: TextStyle(color: AppColors.branco, fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _buildServiceImage(detail),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.title,
                style: const TextStyle(
                  color: AppColors.preto,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip('Prazo: ${_formatDate(detail.deadline)}'),
                  _buildInfoChip(detail.modality),
                  _buildInfoChip('${detail.timeChronos} Chronos'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                detail.description,
                style: const TextStyle(
                  color: AppColors.preto,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (detail.categoryEntities.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detail.categoryEntities
                .map((category) => _buildCategoryChip(category.name))
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.amareloClaro,
                child: Text(
                  detail.userCreator.name.isEmpty
                      ? '?'
                      : detail.userCreator.name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.preto),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Publicado por',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail.userCreator.name,
                      style: const TextStyle(
                        color: AppColors.preto,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildActionButtons(detail),
      ],
    );
  }

  Widget _buildServiceImage(ServiceDetailModel detail) {
    return ServiceImage(
      imageSource: detail.serviceImageUrl,
      height: 240,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholderColor: const Color(0xFFD8DBD2),
      iconColor: Colors.grey,
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.amareloClaro,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.preto,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.preto,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ServiceDetailModel detail) {
    if (_isOwner && detail.id != null) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _editRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloUmPoucoEscuro,
                foregroundColor: AppColors.branco,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Editar pedido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _cancelRequest,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Cancelar pedido',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (!_showAcceptAction) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amareloUmPoucoEscuro,
            foregroundColor: AppColors.branco,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Voltar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Fluxo de aceitacao ainda nao foi ligado nesta branch.'),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amareloUmPoucoEscuro,
          foregroundColor: AppColors.branco,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Aceitar pedido',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  }
}
