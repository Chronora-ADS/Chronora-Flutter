import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/models/main_page_requests_model.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/services/auth_session_service.dart';
import '../../widgets/header.dart';
import '../../widgets/pending_service_cancellation_obligations.dart';
import '../../widgets/service_image.dart';
import '../../widgets/animated_side_menu_overlay.dart';
import '../../widgets/wallet_modal.dart';
import 'request_accepted_view.dart';

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
  int? _currentUserId;
  String? _currentUserName;
  int? _currentUserPhone;
  double? _currentUserRating;
  AcceptedRequestInfo? _acceptedRequestInfo;
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

      final currentUser = await _fetchCurrentUser(token);
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
      final acceptedInfo = detail.acceptedRequestInfo?.hasAcceptedUser == true
          ? detail.acceptedRequestInfo
          : null;
      final isOwner = detail.userCreator.id == currentUser?.id;
      setState(() {
        _currentUserId = currentUser?.id;
        _currentUserName = currentUser?.name;
        _currentUserPhone = currentUser?.phoneNumber;
        _currentUserRating = currentUser?.rating;
        _serviceDetail = detail;
        _isOwner = isOwner;
        _acceptedRequestInfo = acceptedInfo;
        _isLoading = false;
      });

      final normalizedStatus = detail.status.trim().toUpperCase();
      if (normalizedStatus == 'EM_ANDAMENTO' ||
          normalizedStatus == 'AGUARDANDO_CONFIRMACAO') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.orderInProgress,
            arguments: detail,
          );
        });
        return;
      }

      if (normalizedStatus == 'CONCLUIDO' || normalizedStatus == 'CANCELADO') {
        return;
      }

      _routeToAcceptedRequestIfNeeded(detail, acceptedInfo, isOwner: isOwner);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<_CurrentUser?> _fetchCurrentUser(String token) async {
    try {
      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['user'] is Map<String, dynamic>
            ? decoded['user'] as Map<String, dynamic>
            : decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded;
        return _CurrentUser.fromJson(data);
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

      final response = detail?.acceptedRequestInfo?.hasAcceptedUser != null
          ? await ApiService.put(
              '/service/cancelService/${detail!.id}',
              {},
              token: token,
            )
          : await ApiService.delete(
              '/service/delete/${detail!.id}',
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
      AppSnackBar.show(context, 'Pedido cancelado com sucesso.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
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

  Future<void> _acceptRequest() async {
    final canContinue =
        await PendingServiceCancellationObligations.ensureCanContinue(
      context,
      actionLabel: 'aceitar pedido',
    );
    if (!canContinue || !mounted) {
      return;
    }

    final detail = _serviceDetail;
    if (detail?.id == null) return;
    final serviceId = detail!.id!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) {
        throw Exception('Usuario nao autenticado.');
      }

      final latestDetail = await _fetchServiceDetailSnapshot(serviceId, token);
      final latestAcceptedInfo = latestDetail?.acceptedRequestInfo;
      if (_isAcceptedByAnotherProvider(latestAcceptedInfo)) {
        throw Exception('O pedido ja foi aceito por outro usuario.');
      }

      final response = await ApiService.put(
        '/service/acceptService/$serviceId',
        const {},
        token: token,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          ApiService.extractErrorMessage(
            response.body,
            fallback: 'Nao foi possivel aceitar o pedido.',
          ),
        );
      }

      final acceptedDetail = _parseServiceDetailFromBody(response.body) ??
          await _fetchServiceDetailSnapshot(serviceId, token) ??
          latestDetail ??
          detail;
      final acceptedInfo = _resolveAcceptedRequestInfo(acceptedDetail);

      if (!mounted) return;
      setState(() {
        _serviceDetail = acceptedDetail;
        _acceptedRequestInfo = acceptedInfo;
        _isOwner = false;
        _isLoading = false;
      });

      _openAcceptedRequest(
        detail: acceptedDetail,
        acceptedInfo: acceptedInfo,
        audience: RequestAcceptedAudience.provider,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      AppSnackBar.show(context, _buildAcceptRequestErrorMessage(e), isError: true);
    }
  }

  Future<ServiceDetailModel?> _fetchServiceDetailSnapshot(
    int serviceId,
    String token,
  ) async {
    final response =
        await ApiService.get('/service/get/$serviceId', token: token);
    if (response.statusCode != 200) {
      return null;
    }

    return _parseServiceDetailFromBody(response.body);
  }

  ServiceDetailModel? _parseServiceDetailFromBody(String body) {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(trimmedBody);
    if (decoded is Map<String, dynamic>) {
      return ServiceDetailModel.fromJson(decoded);
    }

    return null;
  }

  AcceptedRequestInfo _resolveAcceptedRequestInfo(ServiceDetailModel detail) {
    final backendInfo = detail.acceptedRequestInfo;
    if (backendInfo != null && backendInfo.hasAcceptedUser) {
      return backendInfo;
    }

    return AcceptedRequestInfo(
      acceptedUser: UserCreator(
        id: _currentUserId,
        name: (_currentUserName?.trim().isNotEmpty ?? false)
            ? _currentUserName!.trim()
            : 'Prestador',
        phoneNumber: _currentUserPhone,
        rating: _currentUserRating,
      ),
      acceptedAt: DateTime.now().toIso8601String(),
      authenticationCode: backendInfo?.authenticationCode,
      expiresAt: backendInfo?.expiresAt,
    );
  }

  void _openRequesterAcceptedPreview() {
    final detail = _serviceDetail;
    final acceptedInfo = _acceptedRequestInfo ?? detail?.acceptedRequestInfo;

    if (detail == null || acceptedInfo?.hasAcceptedUser != true) {
      AppSnackBar.show(context, 'O pedido ainda nao foi aceito.', isError: true);
      return;
    }

    _openAcceptedRequest(
      detail: detail,
      acceptedInfo: acceptedInfo!,
      audience: RequestAcceptedAudience.requester,
    );
  }

  void _openAcceptedRequest({
    required ServiceDetailModel detail,
    required AcceptedRequestInfo acceptedInfo,
    required RequestAcceptedAudience audience,
    bool replace = false,
  }) {
    final arguments = {
      'serviceId': detail.id,
      'serviceDetail': detail,
      'audience': audience,
      'acceptedUserName': acceptedInfo.acceptedUser?.name,
      'acceptedUserPhone': acceptedInfo.acceptedUser?.phoneNumber,
      'acceptedUserRating': acceptedInfo.acceptedUser?.rating,
      'acceptedAt': acceptedInfo.acceptedAt,
      'authenticationCode': acceptedInfo.authenticationCode,
      'authenticationCodeExpiresAt': acceptedInfo.expiresAt,
      'verificationCodeCallCount': detail.verificationCodeCallCount,
    };

    if (replace) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.requestAcceptedView,
        arguments: arguments,
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.requestAcceptedView,
      arguments: arguments,
    );
  }

  void _routeToAcceptedRequestIfNeeded(
    ServiceDetailModel detail,
    AcceptedRequestInfo? acceptedInfo, {
    required bool isOwner,
  }) {
    if (isOwner || !_isAcceptedByCurrentProvider(acceptedInfo)) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openAcceptedRequest(
        detail: detail,
        acceptedInfo: acceptedInfo!,
        audience: RequestAcceptedAudience.provider,
        replace: true,
      );
    });
  }

  bool _isAcceptedByCurrentProvider(AcceptedRequestInfo? acceptedInfo) {
    final acceptedUserId = acceptedInfo?.acceptedUser?.id;
    if (acceptedUserId == null || _currentUserId == null) {
      return false;
    }

    return acceptedUserId.toString() == _currentUserId.toString();
  }

  bool _isAcceptedByAnotherProvider(AcceptedRequestInfo? acceptedInfo) {
    if (acceptedInfo?.hasAcceptedUser != true) {
      return false;
    }

    return !_isAcceptedByCurrentProvider(acceptedInfo);
  }

  bool _canOpenAcceptedRequest(AcceptedRequestInfo? acceptedInfo) {
    return acceptedInfo?.hasAcceptedUser == true;
  }

  String _buildAcceptRequestErrorMessage(Object error) {
    final rawMessage = error.toString().toLowerCase();

    if (rawMessage.contains('ja foi aceito')) {
      return 'Erro, o pedido ja foi aceito por outro usuario.';
    }

    if (rawMessage.contains('mais de um pedido')) {
      return 'Erro, voce nao pode aceitar mais de um pedido ao mesmo tempo.';
    }

    if (rawMessage.contains('proprio pedido')) {
      return 'Erro, voce nao pode aceitar o proprio pedido.';
    }

    return error.toString().replaceFirst('Exception: ', '');
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
    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Stack(
        children: [
          _buildBackgroundImages(),
          Column(
            children: [
              Header(
                key: ValueKey(_walletRefreshVersion),
                onMenuPressed: _toggleDrawer,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: _buildContent(),
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
                color: AppColors.preto.withValues(alpha: 0.5),
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

  Widget _buildBackgroundImages() {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 135,
          child: Image.asset(
            'assets/img/Comb2.png',
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Image.asset(
            'assets/img/BarAscending.png',
            width: 210,
            height: 179,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 60,
          child: Image.asset(
            'assets/img/Comb3.png',
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
      ],
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
        _buildRequestCard(detail),
        if (detail.categoryEntities.isNotEmpty) ...[
          const SizedBox(height: 5),
          _buildCategoryList(detail),
        ],
        const SizedBox(height: 20),
        _buildPosterCard(detail),
        const SizedBox(height: 20),
        _buildActionButtons(detail),
      ],
    );
  }

  Widget _buildRequestCard(ServiceDetailModel detail) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              detail.title,
              style: const TextStyle(
                color: AppColors.preto,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.preto,
              border: Border(
                top: BorderSide(
                  color: AppColors.amareloUmPoucoMaisEscuro,
                  width: 3,
                ),
                bottom: BorderSide(
                  color: AppColors.amareloUmPoucoMaisEscuro,
                  width: 3,
                ),
                left: BorderSide(
                  color: AppColors.amareloUmPoucoMaisEscuro,
                  width: 3,
                ),
                right: BorderSide(
                  color: AppColors.amareloUmPoucoMaisEscuro,
                  width: 3,
                ),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final imageWidth = constraints.maxWidth < 340
                        ? 128.0
                        : constraints.maxWidth < 420
                            ? 150.0
                            : 200.0;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: imageWidth,
                            height: imageWidth * 0.565,
                            color: AppColors.cinza,
                            child: _buildServiceImage(detail),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _RequestSummary(
                            deadline: _formatDate(detail.deadline),
                            modality: _formatModality(detail.modality),
                            timeChronos: detail.timeChronos,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  detail.description,
                  style: const TextStyle(
                    color: AppColors.branco,
                    fontSize: 16,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceImage(ServiceDetailModel detail) {
    return ServiceImage(
      imageSource: detail.serviceImageUrl,
      fit: BoxFit.cover,
      placeholderColor: AppColors.cinza,
      iconColor: AppColors.branco,
    );
  }

  Widget _buildCategoryList(ServiceDetailModel detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: detail.categoryEntities
            .map((category) => _buildCategoryChip(category.name))
            .toList(),
      ),
    );
  }

  Widget _buildCategoryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.amareloClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.preto,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildPosterCard(ServiceDetailModel detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Postado as ${_formatTime(detail.postedAt)} por:',
            style: const TextStyle(
              color: AppColors.preto,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.amareloClaro,
                child: Text(
                  detail.userCreator.name.isEmpty
                      ? '?'
                      : detail.userCreator.name[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.branco),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.userCreator.name.isEmpty
                          ? 'Solicitante'
                          : detail.userCreator.name,
                      style: const TextStyle(
                        color: AppColors.preto,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildRatingRow(detail.userCreator.rating),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(double? rating) {
    return Row(
      children: [
        Text(
          (rating ?? 0.0).toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.preto,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.star,
          color: AppColors.amareloClaro,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ServiceDetailModel detail) {
    final acceptedInfo = _acceptedRequestInfo ?? detail.acceptedRequestInfo;
    final canOpenAcceptedRequest = _canOpenAcceptedRequest(acceptedInfo);
    final normalizedStatus = detail.status.trim().toUpperCase();
    final isTerminal =
        normalizedStatus == 'CONCLUIDO' || normalizedStatus == 'CANCELADO';
    if (_isOwner && detail.id != null && !isTerminal) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _editRequest,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.amareloUmPoucoEscuro,
                foregroundColor: AppColors.branco,
                side: const BorderSide(color: AppColors.amareloUmPoucoEscuro),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Editar pedido',
                style: TextStyle(
                  color: AppColors.branco,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cancelRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.preto,
                foregroundColor: AppColors.branco,
                side: const BorderSide(
                  color: AppColors.amareloUmPoucoEscuro,
                  width: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Cancelar pedido',
                style: TextStyle(
                  color: AppColors.branco,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed:
                  canOpenAcceptedRequest ? _openRequesterAcceptedPreview : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: canOpenAcceptedRequest
                    ? AppColors.amareloClaro
                    : AppColors.cinza,
                foregroundColor: AppColors.preto,
                disabledForegroundColor: Colors.black45,
                side: BorderSide(
                  color: canOpenAcceptedRequest
                      ? AppColors.amareloUmPoucoEscuro
                      : AppColors.cinza,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Ver pedido aceito',
                style: TextStyle(
                  fontSize: 22,
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
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Voltar',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_isAcceptedByCurrentProvider(acceptedInfo)) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _openAcceptedRequest(
            detail: detail,
            acceptedInfo: acceptedInfo!,
            audience: RequestAcceptedAudience.provider,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amareloUmPoucoEscuro,
            foregroundColor: AppColors.branco,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Ver pedido aceito',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_isAcceptedByAnotherProvider(acceptedInfo)) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Pedido ja aceito',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _acceptRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amareloUmPoucoEscuro,
          foregroundColor: AppColors.branco,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Aceitar pedido',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatModality(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'remote' ||
        normalized == 'remoto' ||
        normalized == 'a distancia') {
      return 'Remoto';
    }
    if (normalized == 'presential' || normalized == 'presencial') {
      return 'Presencial';
    }
    return value;
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

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) {
      return '--:--';
    }

    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    if (value.contains('T') && value.length >= 16) {
      return value.split('T')[1].substring(0, 5);
    }

    return '--:--';
  }
}

class _RequestSummary extends StatelessWidget {
  final String deadline;
  final String modality;
  final int timeChronos;

  const _RequestSummary({
    required this.deadline,
    required this.modality,
    required this.timeChronos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildChip('Prazo: $deadline'),
        const SizedBox(height: 8),
        _buildChip(modality),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/img/CoinYellow.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.monetization_on,
                  color: AppColors.amareloClaro,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$timeChronos Chronos',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.amareloClaro,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.amareloUmPoucoEscuro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        style: const TextStyle(
          color: AppColors.branco,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _CurrentUser {
  final int? id;
  final String? name;
  final int? phoneNumber;
  final double? rating;

  const _CurrentUser({
    this.id,
    this.name,
    this.phoneNumber,
    this.rating,
  });

  factory _CurrentUser.fromJson(Map<String, dynamic> json) {
    return _CurrentUser(
      id: _toInt(json['id']),
      name: json['name']?.toString(),
      phoneNumber: _toInt(json['phoneNumber']),
      rating:
          _toDouble(json['rating'] ?? json['userRating'] ?? json['avaliacao']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }
}
