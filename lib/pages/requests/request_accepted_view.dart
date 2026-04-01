import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/services/api_service.dart';
import '../../widgets/header.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';

enum RequestAcceptedAudience { provider, requester }

class RequestAcceptedView extends StatefulWidget {
  final ServiceDetailModel? serviceDetail;
  final RequestAcceptedAudience audience;

  const RequestAcceptedView({
    super.key,
    this.serviceDetail,
    this.audience = RequestAcceptedAudience.provider,
  });

  @override
  State<RequestAcceptedView> createState() => _RequestAcceptedViewState();
}

class _RequestAcceptedViewState extends State<RequestAcceptedView> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isShowingDetails = false;
  bool _didLoadArguments = false;

  ServiceDetailModel? _resolvedServiceDetail;
  late RequestAcceptedAudience _resolvedAudience;

  final GlobalKey _requestCardKey = GlobalKey();
  double _requestCardHeight = 260;

  String _acceptedUserName = 'Prestador';
  int? _acceptedUserPhone;
  DateTime _acceptedAt = DateTime.now();
  String _authenticationCode = '1234';
  DateTime? _authenticationCodeExpiresAt;
  Duration _remainingCodeTime = Duration.zero;
  Timer? _countdownTimer;
  bool _hasHandledCodeExpiration = false;
  bool _isStartingService = false;

  bool get _isRequesterView =>
      _resolvedAudience == RequestAcceptedAudience.requester;

  @override
  void initState() {
    super.initState();
    _resolvedAudience = widget.audience;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadArguments) return;
    _didLoadArguments = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is ServiceDetailModel) {
      _resolvedServiceDetail = arguments;
    } else if (arguments is Map) {
      final serviceDetail = arguments['serviceDetail'];
      if (serviceDetail is ServiceDetailModel) {
        _resolvedServiceDetail = serviceDetail;
      } else {
        _resolvedServiceDetail = widget.serviceDetail;
      }

      final acceptedUserName = (arguments['acceptedUserName'] as String?)?.trim();
      final acceptedUserPhone = arguments['acceptedUserPhone'];
      final audience = arguments['audience'];
      final isRequesterView = arguments['isRequesterView'] == true;
      final authenticationCode =
          (arguments['authenticationCode'] as String?)?.trim() ??
          (arguments['startAuthenticationCode'] as String?)?.trim();
      final acceptedAt = arguments['acceptedAt'];
      final authenticationCodeExpiresAt = arguments['authenticationCodeExpiresAt'];

      if (acceptedUserName != null && acceptedUserName.isNotEmpty) {
        _acceptedUserName = acceptedUserName;
      }

      if (acceptedUserPhone is int) {
        _acceptedUserPhone = acceptedUserPhone;
      }

      if (audience is RequestAcceptedAudience) {
        _resolvedAudience = audience;
      } else if (audience is String) {
        final normalizedAudience = audience.trim().toLowerCase();
        if (normalizedAudience == 'requester' ||
            normalizedAudience == 'solicitante') {
          _resolvedAudience = RequestAcceptedAudience.requester;
        } else if (normalizedAudience == 'provider' ||
            normalizedAudience == 'prestador') {
          _resolvedAudience = RequestAcceptedAudience.provider;
        }
      } else if (isRequesterView) {
        _resolvedAudience = RequestAcceptedAudience.requester;
      }

      if (authenticationCode != null && authenticationCode.isNotEmpty) {
        _authenticationCode = authenticationCode;
      }

      if (acceptedAt is DateTime) {
        _acceptedAt = acceptedAt;
      } else if (acceptedAt is String && acceptedAt.isNotEmpty) {
        try {
          _acceptedAt = DateTime.parse(acceptedAt);
        } catch (_) {}
      }

      if (authenticationCodeExpiresAt is DateTime) {
        _authenticationCodeExpiresAt = authenticationCodeExpiresAt;
      } else if (authenticationCodeExpiresAt is String &&
          authenticationCodeExpiresAt.isNotEmpty) {
        try {
          _authenticationCodeExpiresAt =
              DateTime.parse(authenticationCodeExpiresAt);
        } catch (_) {}
      }
    } else {
      _resolvedServiceDetail = widget.serviceDetail;
    }

    final acceptedInfo = _resolvedServiceDetail?.acceptedRequestInfo;
    if (acceptedInfo?.acceptedUser?.name.trim().isNotEmpty == true &&
        _acceptedUserName == 'Prestador') {
      _acceptedUserName = acceptedInfo!.acceptedUser!.name.trim();
    }
    _acceptedUserPhone ??= acceptedInfo?.acceptedUser?.phoneNumber;
    _authenticationCode =
        (acceptedInfo?.authenticationCode?.trim().isNotEmpty ?? false)
            ? acceptedInfo!.authenticationCode!.trim()
            : _authenticationCode;
    if (acceptedInfo?.acceptedAt?.trim().isNotEmpty == true) {
      try {
        _acceptedAt = DateTime.parse(acceptedInfo!.acceptedAt!.trim());
      } catch (_) {}
    }
    if (acceptedInfo?.expiresAt?.trim().isNotEmpty == true) {
      try {
        _authenticationCodeExpiresAt =
            DateTime.parse(acceptedInfo!.expiresAt!.trim());
      } catch (_) {}
    }

    if (!_isRequesterView) {
      _loadAcceptedUser();
    }

    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  void _startCountdown() {
    _countdownTimer?.cancel();
    _syncRemainingCodeTime();

    if (_authenticationCodeExpiresAt == null || _hasHandledCodeExpiration) {
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncRemainingCodeTime();
    });
  }

  void _syncRemainingCodeTime() {
    final expiresAt = _authenticationCodeExpiresAt;
    if (expiresAt == null) return;

    final remaining = expiresAt.difference(DateTime.now());
    final nextValue = remaining.isNegative ? Duration.zero : remaining;

    if (mounted) {
      setState(() {
        _remainingCodeTime = nextValue;
      });
    } else {
      _remainingCodeTime = nextValue;
    }

    if (nextValue == Duration.zero && !_hasHandledCodeExpiration) {
      _handleCodeExpiration();
    }
  }

  Future<void> _handleCodeExpiration() async {
    if (_hasHandledCodeExpiration || !mounted) return;

    _hasHandledCodeExpiration = true;
    _countdownTimer?.cancel();

    await _clearAcceptedRequestCache();
    await _resetAcceptedRequestOnServerIfNeeded();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('O tempo para usar o codigo terminou.'),
          backgroundColor: AppColors.vermelho,
        ),
      );

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.main,
      (route) => false,
    );
  }

  Future<void> _clearAcceptedRequestCache() async {
    final serviceId = _resolvedServiceDetail?.id;
    if (serviceId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accepted_request_info_$serviceId');
  }

  Future<void> _resetAcceptedRequestOnServerIfNeeded() async {
    if (_isRequesterView) return;

    final serviceId = _resolvedServiceDetail?.id;
    if (serviceId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      await ApiService.put(
        '/service/cancelService/$serviceId',
        const {},
        token: token,
      );
    } catch (_) {}
  }

  Future<void> _copyPhoneNumber(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Numero copiado para a area de transferencia'),
          backgroundColor: Colors.green,
        ),
      );
  }

  void _updateRequestCardHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _requestCardKey.currentContext;
      if (context == null) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      final nextHeight = renderBox?.size.height;
      if (nextHeight == null) return;

      if ((nextHeight - _requestCardHeight).abs() > 0.5 && mounted) {
        setState(() {
          _requestCardHeight = nextHeight;
        });
      }
    });
  }

  Future<void> _loadAcceptedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode != 200) return;

      final userData = json.decode(response.body) as Map<String, dynamic>;
      final resolvedUserData = userData['user'] is Map<String, dynamic>
          ? userData['user'] as Map<String, dynamic>
          : userData;
      if (!mounted) return;

      setState(() {
        final name = (resolvedUserData['name'] as String?)?.trim();
        _acceptedUserName =
            name != null && name.isNotEmpty ? name : _acceptedUserName;
        _acceptedUserPhone =
            resolvedUserData['phoneNumber'] as int? ?? _acceptedUserPhone;
      });
    } catch (_) {}
  }

  Future<void> _openStartServiceModal() async {
    final codeController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: !_isStartingService,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (_isStartingService) return;

              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Informe o codigo para iniciar o servico.'),
                    backgroundColor: AppColors.vermelho,
                  ),
                );
                return;
              }

              setModalState(() => _isStartingService = true);

              try {
                await _startService(code);
                if (!mounted) return;
                Navigator.of(dialogContext).pop();
              } finally {
                if (dialogContext.mounted) {
                  setModalState(() => _isStartingService = false);
                } else {
                  _isStartingService = false;
                }
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.branco,
              title: const Text('Iniciar servico'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Digite o codigo informado pelo requisitante.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      hintText: '0000',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLiveCountdownStatus(
                    emphasizeExpired: true,
                    textColor: AppColors.preto,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isStartingService
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed:
                      (_remainingCodeTime == Duration.zero || _isStartingService)
                          ? null
                          : submit,
                  child: _isStartingService
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _startService(String code) async {
    final serviceId = _resolvedServiceDetail?.id;
    if (serviceId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Usuario nao autenticado');
    }

    final response = await ApiService.putString(
      '/service/startService/$serviceId',
      code,
      token: token,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      await _clearAcceptedRequestCache();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servico iniciado com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (route) => false,
      );
      return;
    }

    final body = response.body.toLowerCase();
    if (body.contains('expir')) {
      await _handleCodeExpiration();
      return;
    }

    throw Exception(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Stack(
        children: [
          _buildBackground(),
          Column(
            children: [
              Header(onMenuPressed: _toggleDrawer),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: _buildPageContent(),
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
                color: AppColors.preto.withOpacity(0.5),
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
            Positioned.fill(
              child: Container(
                color: AppColors.preto.withOpacity(0.5),
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

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: 150,
          right: 0,
          child: Image.asset(
            'assets/img/Comb3.png',
            width: 110,
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Image.asset(
            'assets/img/BarAscending.png',
            width: 210,
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildPageContent() {
    const double detailsHorizontalInset = 3;
    const double topContentOffset = 0;

    _updateRequestCardHeight();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            KeyedSubtree(
              key: _requestCardKey,
              child: _buildRequestCard(),
            ),
            const SizedBox(height: 16),
            _buildPosterCard(),
            if (_isRequesterView) ...[
              const SizedBox(height: 12),
              _buildAcceptedProviderCard(),
              const SizedBox(height: 18),
              _buildAuthenticationCodeCard(),
            ] else ...[
              const SizedBox(height: 12),
              _buildCalloutCard(),
              const SizedBox(height: 12),
              _buildAcceptedProviderCard(),
              const SizedBox(height: 18),
              _buildStartButton(),
            ],
          ],
        ),
        Positioned(
          top: topContentOffset + _requestCardHeight - 3,
          left: detailsHorizontalInset,
          right: detailsHorizontalInset,
          child: IgnorePointer(
            ignoring: !_isShowingDetails,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              offset:
                  _isShowingDetails ? Offset.zero : const Offset(0, -0.16),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _isShowingDetails ? 1 : 0,
                child: _buildDetailsOverlay(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard() {
    final serviceDetail = _resolvedServiceDetail;

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
              serviceDetail?.title.isNotEmpty == true
                  ? serviceDetail!.title
                  : 'Titulo do pedido Lorem Ipsum',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.preto,
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
                  color: AppColors.amareloUmPoucoEscuro,
                  width: 3,
                ),
                right: BorderSide(
                  color: AppColors.amareloUmPoucoEscuro,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 200,
                    height: 113,
                    color: AppColors.cinza,
                    child: _buildServiceImage(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RequestSummary(
                    deadline: _formatDate(serviceDetail?.deadline),
                    modality: _formatModality(serviceDetail?.modality),
                    timeChronos: serviceDetail?.timeChronos ?? 100,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _isShowingDetails = !_isShowingDetails;
              });
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.amareloUmPoucoEscuro,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Mais detalhes',
                    style: TextStyle(
                      color: AppColors.branco,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isShowingDetails ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.branco,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsOverlay() {
    final description = _resolvedServiceDetail?.description;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.preto,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
        border: Border.all(color: AppColors.amareloUmPoucoEscuro, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        description != null && description.isNotEmpty
            ? description
            : 'Preciso de um profissional para realizar a pintura de uma parede interna, com acabamento uniforme e atencao aos detalhes.',
        style: const TextStyle(
          color: AppColors.branco,
          fontSize: 17.5,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _buildPosterCard() {
    final creator = _resolvedServiceDetail?.userCreator;

    return _InfoCard(
      header: 'Postado as ${_formatTime(_resolvedServiceDetail?.postedAt)} por:',
      highlightBorder: _isRequesterView,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator?.name.isNotEmpty == true ? creator!.name : 'Solicitante',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.preto,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Text(
                      '4.9',
                      style: TextStyle(fontSize: 16, color: AppColors.preto),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.star, size: 19, color: AppColors.preto),
                  ],
                ),
                if (_isRequesterView) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _formatPhoneNumber(creator?.phoneNumber),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.preto,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.phone_in_talk,
                        color: AppColors.preto,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalloutCard() {
    final phone = _formatPhoneNumber(_resolvedServiceDetail?.userCreator.phoneNumber);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.amareloClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amareloUmPoucoEscuro, width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              'assets/img/gradiant_bars_up.png',
              width: 50,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 4,
            child: Image.asset(
              'assets/img/gradiant_bars_down.png',
              width: 52,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Antes de aceitar o\npedido, contate o solicitante\npelo telefone:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.preto,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () => _copyPhoneNumber(phone),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        phone,
                        style: const TextStyle(
                          color: AppColors.preto,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.phone_in_talk,
                        color: AppColors.preto,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedProviderCard() {
    final acceptedPhone = _formatPhoneNumber(_acceptedUserPhone);

    return _InfoCard(
      header: 'Aceito as ${_formatTimeFromDateTime(_acceptedAt)} por:',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _acceptedUserName,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.preto,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Text(
                      '5.0',
                      style: TextStyle(fontSize: 16, color: AppColors.preto),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.star, size: 19, color: AppColors.preto),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      acceptedPhone,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.preto,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.phone_in_talk,
                      color: AppColors.preto,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticationCodeCard() {
    return _InfoCard(
      headerWidget: Row(
        children: [
          const Expanded(
            child: Text(
              'Codigo de autenticacao de inicio',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.preto,
              ),
            ),
          ),
          const Icon(
            Icons.help,
            size: 18,
            color: AppColors.preto,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: _buildCountdownStatus(textColor: AppColors.preto),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 2, left: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _remainingCodeTime == Duration.zero ? '----' : _authenticationCode,
                style: const TextStyle(
                  fontSize: 28,
                  color: AppColors.vermelho,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _buildCountdownStatus(
              textColor: AppColors.preto,
              emphasizeExpired: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownStatus({
    Color textColor = AppColors.branco,
    bool emphasizeExpired = false,
  }) {
    final hasCountdown = _authenticationCodeExpiresAt != null;
    final isExpired = hasCountdown && _remainingCodeTime == Duration.zero;

    final text = !hasCountdown
        ? 'Sem tempo definido'
        : isExpired
            ? 'Tempo esgotado'
            : 'Tempo restante: ${_formatDuration(_remainingCodeTime)}';

    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: isExpired && emphasizeExpired ? AppColors.vermelho : textColor,
        fontWeight:
            isExpired || !hasCountdown ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildLiveCountdownStatus({
    Color textColor = AppColors.branco,
    bool emphasizeExpired = false,
  }) {
    if (_authenticationCodeExpiresAt == null) {
      return _buildCountdownStatus(
        textColor: textColor,
        emphasizeExpired: emphasizeExpired,
      );
    }

    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (value) => value),
      builder: (context, snapshot) {
        return _buildCountdownStatus(
          textColor: textColor,
          emphasizeExpired: emphasizeExpired,
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }

  bool get _canStartService =>
      _remainingCodeTime > Duration.zero &&
      _resolvedServiceDetail?.id != null &&
      _authenticationCode.trim().isNotEmpty;

  Widget _buildAvatar() {
    return const CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.amareloClaro,
      child: Icon(Icons.person, color: AppColors.preto, size: 30),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canStartService ? _openStartServiceModal : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amareloUmPoucoEscuro,
          foregroundColor: AppColors.branco,
          disabledBackgroundColor: AppColors.cinza,
          disabledForegroundColor: AppColors.branco,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          _remainingCodeTime == Duration.zero
              ? 'Tempo esgotado'
              : 'Iniciar pedido',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildServiceImage() {
    final imageUrl = _resolvedServiceDetail?.serviceImageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallbackImage(),
      );
    }

    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Container(
      color: AppColors.cinza,
      child: Image.asset(
        'assets/img/Paintbrush.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.image,
          color: AppColors.cinza,
          size: 40,
        ),
      ),
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return '30/10/2025';
    }

    try {
      final parts = rawDate.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}

    return rawDate;
  }

  String _formatModality(String? modality) {
    if (modality == null || modality.isEmpty) {
      return 'Presencial';
    }

    final normalized = modality.trim().toLowerCase();
    if (normalized == 'remote' ||
        normalized == 'remoto' ||
        normalized == 'a distancia') {
      return 'Remoto';
    }

    return modality;
  }

  String _formatPhoneNumber(int? phoneNumber) {
    if (phoneNumber == null) {
      return '+55 00 00000-0000';
    }

    final digits = phoneNumber.toString().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return digits;
    }

    final normalized =
        digits.length > 11 ? digits.substring(digits.length - 11) : digits;
    final ddd = normalized.substring(0, 2);
    final prefix = normalized.substring(2, 7);
    final suffix = normalized.substring(7);
    return '+55 $ddd $prefix-$suffix';
  }

  String _formatTime(String? rawDateTime) {
    if (rawDateTime == null || rawDateTime.isEmpty) {
      return '--:--';
    }

    try {
      return _formatTimeFromDateTime(DateTime.parse(rawDateTime));
    } catch (_) {
      if (rawDateTime.contains('T') && rawDateTime.length >= 16) {
        return rawDateTime.split('T')[1].substring(0, 5);
      }
    }

    return '--:--';
  }

  String _formatTimeFromDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
                  color: AppColors.amareloUmPoucoEscuro,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.amareloUmPoucoEscuro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.branco,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String header;
  final Widget? headerWidget;
  final Widget child;
  final bool highlightBorder;

  const _InfoCard({
    this.header = '',
    this.headerWidget,
    required this.child,
    this.highlightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlightBorder ? AppColors.azul : AppColors.cinza,
          width: highlightBorder ? 2.2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerWidget ??
              Text(
                header,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.preto,
                ),
              ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}
