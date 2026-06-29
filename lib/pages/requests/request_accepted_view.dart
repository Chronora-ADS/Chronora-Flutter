import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/models/user_creator.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/backend_date_time_parser.dart';
import '../../core/services/api_service.dart';
import '../../core/services/pending_service_cancellation_service.dart';
import '../../widgets/header.dart';
import '../../widgets/animated_side_menu_overlay.dart';
import '../../widgets/wallet_modal.dart';

enum RequestAcceptedAudience { provider, requester }

enum _ExpiredCodeAction { cancelService, secondCall, timeout }

class _LeaveMessage {
  final String text;
  final bool isError;
  const _LeaveMessage(this.text, {this.isError = false});
}

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
  static const String _orderInProgressServiceIdKey =
      'order_in_progress_service_id';
  static const Duration _authenticationCodeLifetime = Duration(minutes: 2);
  static const Duration _secondCallDecisionTimeout = Duration(minutes: 2);

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isShowingDetails = false;
  bool _didLoadArguments = false;
  bool _isLoadingServiceDetail = false;

  ServiceDetailModel? _resolvedServiceDetail;
  int? _serviceId;
  late RequestAcceptedAudience _resolvedAudience;

  final GlobalKey _requestCardKey = GlobalKey();
  double _requestCardHeight = 260;

  String _acceptedUserName = 'Prestador';
  int? _acceptedUserPhone;
  double? _acceptedUserRating;
  double? _requesterUserRating;
  DateTime _acceptedAt = DateTime.now();
  String _authenticationCode = '';
  DateTime? _authenticationCodeExpiresAt;
  int _authenticationCodeCallCount = 0;
  Duration _remainingAuthenticationCodeTime = Duration.zero;
  Timer? _countdownTimer;
  Timer? _acceptedRequestSyncTimer;
  bool _isHandlingExpiration = false;
  bool _isLeavingAcceptedView = false;
  bool _isSecondCallPromptOpen = false;
  bool _isStartDialogOpen = false;
  bool _didShowProviderExpiredMessage = false;
  bool _isCancellingService = false;

  bool get _isRequesterView =>
      _resolvedAudience == RequestAcceptedAudience.requester;

  bool get _hasAuthenticationCode =>
      RegExp(r'^\d{4}$').hasMatch(_authenticationCode);

  bool get _canUseAuthenticationCode =>
      _hasAuthenticationCode &&
      _hasAuthenticationCodeExpiration &&
      !_isAuthenticationCodeExpired;

  bool get _isSecondCall => _authenticationCodeCallCount >= 2;

  String get _displayAuthenticationCode =>
      _hasAuthenticationCode ? _authenticationCode : '----';

  @override
  void initState() {
    super.initState();
    _resolvedAudience = widget.audience;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _acceptedRequestSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadArguments) return;
    _didLoadArguments = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is ServiceDetailModel) {
      _resolvedServiceDetail = arguments;
      _serviceId = arguments.id;
    } else if (arguments is Map) {
      final serviceDetail = arguments['serviceDetail'];
      if (serviceDetail is ServiceDetailModel) {
        _resolvedServiceDetail = serviceDetail;
        _serviceId = serviceDetail.id;
      } else {
        _resolvedServiceDetail = widget.serviceDetail;
        _serviceId = widget.serviceDetail?.id;
      }

      final rawServiceId = arguments['serviceId'];
      if (_serviceId == null) {
        if (rawServiceId is int) {
          _serviceId = rawServiceId;
        } else if (rawServiceId is String) {
          _serviceId = int.tryParse(rawServiceId);
        }
      }

      final acceptedUserName =
          (arguments['acceptedUserName'] as String?)?.trim();
      final acceptedUserPhone = arguments['acceptedUserPhone'];
      final acceptedUserRating = arguments['acceptedUserRating'];
      final audience = arguments['audience'];
      final isRequesterView = arguments['isRequesterView'] == true;
      final authenticationCode =
          (arguments['authenticationCode'] as String?)?.trim() ??
              (arguments['startAuthenticationCode'] as String?)?.trim();
      final authenticationCodeExpiresAt =
          (arguments['authenticationCodeExpiresAt'] as String?)?.trim() ??
              (arguments['verificationCodeExpiresAt'] as String?)?.trim() ??
              (arguments['expiresAt'] as String?)?.trim();
      final acceptedAt = arguments['acceptedAt'];
      final verificationCodeCallCount =
          _toNullableInt(arguments['verificationCodeCallCount']);

      if (acceptedUserName != null && acceptedUserName.isNotEmpty) {
        _acceptedUserName = acceptedUserName;
      }

      _acceptedUserPhone =
          _toNullableInt(acceptedUserPhone) ?? _acceptedUserPhone;
      _acceptedUserRating =
          _toNullableDouble(acceptedUserRating) ?? _acceptedUserRating;

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

      _applyAuthenticationCodeExpiresAt(authenticationCodeExpiresAt);
      _applyAuthenticationCodeCallCount(verificationCodeCallCount);

      _applyAcceptedAt(acceptedAt);
    } else {
      _resolvedServiceDetail = widget.serviceDetail;
      _serviceId = widget.serviceDetail?.id;
    }

    _syncAcceptedRequestInfoFromServiceDetail();

    _startAuthenticationCodeCountdown();
    _startAcceptedRequestSync();

    if (_isRequesterView) {
      _loadRequesterUser();
    } else {
      _loadAcceptedUser();
    }

    if (_resolvedServiceDetail == null && _serviceId != null) {
      _loadServiceDetailFromBackend();
    }
  }

  void _syncAcceptedRequestInfoFromServiceDetail() {
    final acceptedRequestInfo = _resolvedServiceDetail?.acceptedRequestInfo;

    final acceptedUser = acceptedRequestInfo?.acceptedUser;
    if (acceptedUser != null) {
      if ((acceptedUser.name).trim().isNotEmpty) {
        _acceptedUserName = acceptedUser.name.trim();
      }
      _acceptedUserPhone = acceptedUser.phoneNumber ?? _acceptedUserPhone;
      _acceptedUserRating = acceptedUser.rating ?? _acceptedUserRating;
    }

    final acceptedCode = acceptedRequestInfo?.authenticationCode?.trim();
    if (acceptedCode != null && acceptedCode.isNotEmpty) {
      _authenticationCode = acceptedCode;
    }

    _applyAuthenticationCodeCallCount(
      _resolvedServiceDetail?.verificationCodeCallCount,
    );
    _applyAuthenticationCodeExpiresAt(acceptedRequestInfo?.expiresAt);

    final serviceAcceptedAt = acceptedRequestInfo?.acceptedAt?.trim();
    _applyAcceptedAt(serviceAcceptedAt);
    _inferAcceptedAtFromExpirationIfMissing(serviceAcceptedAt);
  }

  Future<void> _loadServiceDetailFromBackend() async {
    final serviceId = _serviceId;
    if (serviceId == null || _isLoadingServiceDetail) {
      return;
    }

    setState(() {
      _isLoadingServiceDetail = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        return;
      }

      final response =
          await ApiService.get('/service/get/$serviceId', token: token);
      if (response.statusCode != 200) {
        return;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final detail = ServiceDetailModel.fromJson(decoded);
      if (!mounted) {
        return;
      }

      setState(() {
        _resolvedServiceDetail = detail;
        _serviceId = detail.id ?? _serviceId;
        _syncAcceptedRequestInfoFromServiceDetail();
      });

      _startAuthenticationCodeCountdown();
      _startAcceptedRequestSync();

      if (_isRequesterView) {
        await _loadRequesterUser();
      } else {
        await _loadAcceptedUser();
      }
    } catch (_) {
      // Se a busca falhar, a tela ainda pode usar os dados vindos por argumento.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingServiceDetail = false;
        });
      } else {
        _isLoadingServiceDetail = false;
      }
    }
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

  int? _toNullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value.replaceAll(RegExp(r'\D'), ''));
    }
    return null;
  }

  double? _toNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.'));
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    return BackendDateTimeParser.parse(value);
  }

  void _applyAcceptedAt(dynamic value) {
    final parsed = _parseDateTime(value);
    if (parsed != null) {
      _acceptedAt = parsed;
    }
  }

  void _inferAcceptedAtFromExpirationIfMissing(String? acceptedAt) {
    if (acceptedAt != null && acceptedAt.trim().isNotEmpty) {
      return;
    }

    final expiresAt = _authenticationCodeExpiresAt;
    if (expiresAt != null) {
      _acceptedAt = expiresAt.subtract(_authenticationCodeLifetime);
    }
  }

  Future<void> _copyPhoneNumber(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) return;
    AppSnackBar.show(context, 'Número copiado para a área de transferência');
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
        _acceptedUserPhone = _toNullableInt(resolvedUserData['phoneNumber']) ??
            _acceptedUserPhone;
        _acceptedUserRating = _toNullableDouble(
              resolvedUserData['rating'] ??
                  resolvedUserData['userRating'] ??
                  resolvedUserData['avaliacao'],
            ) ??
            _acceptedUserRating;
      });
    } catch (_) {}
  }

  Future<void> _loadRequesterUser() async {
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
        _requesterUserRating = _toNullableDouble(
              resolvedUserData['rating'] ??
                  resolvedUserData['userRating'] ??
                  resolvedUserData['avaliacao'],
            ) ??
            _requesterUserRating;
      });
    } catch (_) {}
  }

  void _applyAuthenticationCodeExpiresAt(String? rawExpiresAt) {
    if (rawExpiresAt == null || rawExpiresAt.isEmpty) return;

    final parsed = _parseDateTime(rawExpiresAt);
    if (parsed != null) {
      _authenticationCodeExpiresAt = parsed;
    }
  }

  void _applyAuthenticationCodeCallCount(int? callCount) {
    if (callCount != null && callCount > 0) {
      _authenticationCodeCallCount = callCount;
      return;
    }

    if (_authenticationCodeCallCount == 0 && _hasAuthenticationCode) {
      _authenticationCodeCallCount = 1;
    }
  }

  void _startAuthenticationCodeCountdown() {
    _countdownTimer?.cancel();
    _syncRemainingAuthenticationCodeTime();

    if (_authenticationCodeExpiresAt == null) {
      return;
    }

    if (_isAuthenticationCodeExpired) {
      // Se o service detail ainda será carregado do backend, aguardar o
      // carregamento para ter o verificationCodeCallCount atualizado antes
      // de tratar a expiração (evita abrir o dialog de 1ª chamada quando
      // já foi feita a 2ª chamada).
      if (_resolvedServiceDetail == null && _serviceId != null) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleAuthenticationCodeExpired();
      });
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      _syncRemainingAuthenticationCodeTime();
      if (_isAuthenticationCodeExpired) {
        _countdownTimer?.cancel();
        _handleAuthenticationCodeExpired();
      }
    });
  }

  void _syncRemainingAuthenticationCodeTime() {
    final expiresAt = _authenticationCodeExpiresAt;
    final remaining = expiresAt == null
        ? Duration.zero
        : expiresAt.difference(DateTime.now());

    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;

    if (!mounted) {
      _remainingAuthenticationCodeTime = safeRemaining;
      return;
    }

    setState(() {
      _remainingAuthenticationCodeTime = safeRemaining;
    });
  }

  bool get _isAuthenticationCodeExpired =>
      _remainingAuthenticationCodeTime.inSeconds <= 0;

  bool get _hasAuthenticationCodeExpiration =>
      _authenticationCodeExpiresAt != null;

  String get _formattedAuthenticationCodeCountdown {
    final totalSeconds = _remainingAuthenticationCodeTime.inSeconds;
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (safeSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (safeSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleAuthenticationCodeExpired() async {
    if (_isLeavingAcceptedView || _isStartDialogOpen) return;

    if (!_isSecondCall) {
      if (_isRequesterView) {
        await _openSecondCallPrompt();
        return;
      }

      _showProviderWaitingForRequesterDecision();
      return;
    }

    await _expireAcceptedRequestAfterSecondCall();
  }

  void _showProviderWaitingForRequesterDecision() {
    if (_didShowProviderExpiredMessage || !mounted) return;
    _didShowProviderExpiredMessage = true;

    AppSnackBar.show(
      context,
      'O tempo expirou. Aguardando o solicitante decidir a segunda chamada.',
      isError: true,
    );
  }

  Future<void> _expireAcceptedRequestAfterSecondCall() async {
    await _expireAcceptedRequestAndLeave();
  }

  Future<void> _expireAcceptedRequestAfterDecisionTimeout() async {
    await _expireAcceptedRequestAndLeave();
  }

  Future<void> _expireAcceptedRequestAndLeave() async {
    if (_isHandlingExpiration || _isLeavingAcceptedView) return;
    _isHandlingExpiration = true;

    final serviceId = _resolvedServiceDetail?.id;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (serviceId != null) {
        await prefs.remove('accepted_request_info_$serviceId');
      }

      if (serviceId != null && token != null) {
        await ApiService.put(
          '/service/expireAcceptedService/$serviceId',
          const {},
          token: token,
        );
      }
    } catch (_) {
      // A interface ainda deve voltar ao estado inicial mesmo se a chamada falhar.
    }

    await _leaveAcceptedView(
      const _LeaveMessage(
        'A segunda chamada expirou. O serviço foi cancelado e o pedido voltou para aberto.',
        isError: true,
      ),
    );
  }

  Future<void> _openSecondCallPrompt() async {
    if (_isSecondCallPromptOpen ||
        _isHandlingExpiration ||
        _isLeavingAcceptedView) {
      return;
    }

    _isSecondCallPromptOpen = true;
    _isHandlingExpiration = true;
    _countdownTimer?.cancel();

    try {
      final action = await showDialog<_ExpiredCodeAction>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _TimeExpiredActionDialog(
          decisionTimeout: _secondCallDecisionTimeout,
        ),
      );

      _isHandlingExpiration = false;

      if (!mounted || _isLeavingAcceptedView) {
        return;
      }

      if (action == _ExpiredCodeAction.timeout || action == null) {
        await _expireAcceptedRequestAfterDecisionTimeout();
        return;
      }

      if (action == _ExpiredCodeAction.secondCall) {
        await _requestSecondCall();
        return;
      }

      await _openCancelAcceptedServiceFlow(skipConfirmation: true);
    } finally {
      _isSecondCallPromptOpen = false;
      if (!_isLeavingAcceptedView) {
        _isHandlingExpiration = false;
      }
    }
  }

  Future<void> _requestSecondCall() async {
    if (_isHandlingExpiration || _isLeavingAcceptedView) return;

    final serviceId = _resolvedServiceDetail?.id;
    if (serviceId == null) {
      AppSnackBar.show(context, 'Serviço não encontrado.', isError: true);
      return;
    }

    _isHandlingExpiration = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Usuário não autenticado.');
      }

      final response = await ApiService.put(
        '/service/secondCall/$serviceId',
        const {},
        token: token,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          ApiService.extractErrorMessage(
            response.body,
            fallback: 'Não foi possível iniciar a segunda chamada.',
          ),
        );
      }

      final latestDetail = _parseServiceDetailFromResponse(response.body);
      if (!mounted || latestDetail == null) {
        return;
      }

      setState(() {
        _resolvedServiceDetail = latestDetail;
        _serviceId = latestDetail.id ?? _serviceId;
        _syncAcceptedRequestInfoFromServiceDetail();
        _didShowProviderExpiredMessage = false;
      });

      _syncRemainingAuthenticationCodeTime();
      _startAuthenticationCodeCountdown();
      _startAcceptedRequestSync();

      AppSnackBar.show(
          context, 'Segunda chamada iniciada. Um novo código foi gerado.');
    } catch (error) {
      if (!mounted) return;

      AppSnackBar.show(
        context,
        _friendlyErrorMessage(
          error,
          fallback: 'Não foi possível iniciar a segunda chamada.',
        ),
        isError: true,
      );
    } finally {
      _isHandlingExpiration = false;
    }
  }

  ServiceDetailModel? _parseServiceDetailFromResponse(String body) {
    final trimmedBody = body.trim();
    if (trimmedBody.isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        return ServiceDetailModel.fromJson(decoded);
      }
    } catch (_) {}

    return null;
  }

  Future<ServiceDetailModel?> _fetchLatestServiceDetailSnapshot([
    int? serviceIdOverride,
  ]) async {
    final serviceId =
        serviceIdOverride ?? _serviceId ?? _resolvedServiceDetail?.id;
    if (serviceId == null) {
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        return null;
      }

      final response =
          await ApiService.get('/service/get/$serviceId', token: token);
      if (response.statusCode != 200) {
        return null;
      }

      return _parseServiceDetailFromResponse(response.body);
    } catch (_) {
      return null;
    }
  }

  bool _isOrderInProgressStatus(String status) {
    final normalizedStatus = status.trim().toUpperCase();
    return normalizedStatus == 'EM_ANDAMENTO' ||
        normalizedStatus == 'AGUARDANDO_CONFIRMACAO';
  }

  Map<String, Object?> _buildOrderInProgressArguments(
    ServiceDetailModel? detail, {
    int? serviceId,
  }) {
    final resolvedDetail = detail ?? _resolvedServiceDetail;
    final resolvedServiceId = serviceId ?? resolvedDetail?.id ?? _serviceId;

    return {
      if (resolvedServiceId != null) 'serviceId': resolvedServiceId,
      if (resolvedDetail != null) 'serviceDetail': resolvedDetail,
    };
  }

  Future<void> _storeOrderInProgressServiceId(int? serviceId) async {
    if (serviceId == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_orderInProgressServiceIdKey, serviceId);
  }

  Future<bool> _openCancelAcceptedServiceFlow({
    bool skipConfirmation = false,
  }) async {
    if (_isCancellingService || _isLeavingAcceptedView) return false;

    if (!skipConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _CancelServiceConfirmationDialog(),
      );

      if (confirmed != true) {
        return false;
      }
    }

    await _cancelAcceptedService();
    return _isLeavingAcceptedView;
  }

  Future<void> _cancelAcceptedService() async {
    if (_isCancellingService || _isLeavingAcceptedView) return;

    final serviceId = _resolvedServiceDetail?.id;
    if (serviceId == null) {
      AppSnackBar.show(context, 'Serviço não encontrado.', isError: true);
      return;
    }

    setState(() {
      _isCancellingService = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Usuário não autenticado.');
      }

      final response = await ApiService.put(
        '/service/cancelAcceptedService/$serviceId',
        const {},
        token: token,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          ApiService.extractErrorMessage(
            response.body,
            fallback: 'Não foi possível cancelar o serviço.',
          ),
        );
      }

      final pendingJustification = _buildPendingCancellationJustification(
        serviceId,
      );
      await PendingServiceCancellationStore.upsert(pendingJustification);

      await _leaveAcceptedView(
        null,
        {
          'pendingServiceCancellationJustification':
              pendingJustification.toJson(),
        },
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        _friendlyErrorMessage(
          error,
          fallback: 'Não foi possível cancelar o serviço.',
        ),
        isError: true,
      );
    } finally {
      if (mounted && !_isLeavingAcceptedView) {
        setState(() {
          _isCancellingService = false;
        });
      } else {
        _isCancellingService = false;
      }
    }
  }

  PendingServiceCancellationJustification
      _buildPendingCancellationJustification(int serviceId) {
    final detail = _resolvedServiceDetail;
    return PendingServiceCancellationJustification(
      serviceId: serviceId,
      serviceTitle: detail?.title.trim() ?? '',
      requesterName: detail?.userCreator.name.trim() ?? '',
      createdAt: DateTime.now(),
    );
  }

  String _friendlyErrorMessage(Object error, {required String fallback}) {
    final rawMessage = error.toString().replaceFirst(
          RegExp(r'^Exception:\s*'),
          '',
        );
    return ApiService.extractErrorMessage(rawMessage, fallback: fallback);
  }

  Future<void> _openStartRequestDialog() async {
    if (_isStartDialogOpen || _isLeavingAcceptedView) return;

    _isStartDialogOpen = true;
    _countdownTimer?.cancel();
    final serviceId = _serviceId ?? _resolvedServiceDetail?.id;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _StartRequestDialog(
            serviceId: serviceId,
            authenticationCode: _authenticationCode,
            authenticationCodeExpiresAt: _authenticationCodeExpiresAt,
            onSuccess: (startedServiceId) async {
              _serviceId ??= startedServiceId;
              final latestDetail =
                  await _fetchLatestServiceDetailSnapshot(startedServiceId);
              final detailForNavigation =
                  latestDetail ?? _resolvedServiceDetail;
              if (mounted && latestDetail != null) {
                setState(() {
                  _resolvedServiceDetail = latestDetail;
                  _serviceId = latestDetail.id ?? _serviceId;
                  _syncAcceptedRequestInfoFromServiceDetail();
                });
              }

              if (!mounted) return;

              await _storeOrderInProgressServiceId(startedServiceId);

              if (!mounted) return;

              await _leaveAcceptedView(
                const _LeaveMessage(
                  'Código validado. Acompanhe o pedido iniciado em Pedidos em Andamento.',
                ),
                _buildOrderInProgressArguments(
                  detailForNavigation,
                  serviceId: startedServiceId,
                ),
                AppRoutes.orderInProgress,
              );
            },
          );
        },
      );
    } finally {
      _isStartDialogOpen = false;
      if (!_isLeavingAcceptedView) {
        _startAuthenticationCodeCountdown();
      }
    }
  }

  void _startAcceptedRequestSync() {
    _acceptedRequestSyncTimer?.cancel();

    final serviceId = _resolvedServiceDetail?.id;
    if (serviceId == null) {
      return;
    }

    _acceptedRequestSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _syncAcceptedRequestState();
    });
  }

  Future<void> _syncAcceptedRequestState() async {
    if (_isLeavingAcceptedView) return;

    final serviceId = _resolvedServiceDetail?.id;
    if (serviceId == null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        return;
      }

      final response =
          await ApiService.get('/service/get/$serviceId', token: token);
      if (response.statusCode != 200) {
        return;
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final latestDetail = ServiceDetailModel.fromJson(decoded);
      final normalizedStatus = latestDetail.status.trim().toUpperCase();

      if (_isOrderInProgressStatus(normalizedStatus)) {
        await _storeOrderInProgressServiceId(serviceId);
        await _leaveAcceptedView(
          _isRequesterView
              ? _LeaveMessage(
                  'Pedido iniciado por $_acceptedUserName. Acompanhe em Pedidos em Andamento.',
                )
              : null,
          _buildOrderInProgressArguments(latestDetail, serviceId: serviceId),
          AppRoutes.orderInProgress,
        );
        return;
      }

      // Descarta dados desatualizados do sync para não reverter a contagem de
      // chamadas já confirmada localmente (evita reabrir dialog de segunda
      // chamada com dados da 1ª chamada que chegaram com atraso do backend).
      if (latestDetail.verificationCodeCallCount <
          _authenticationCodeCallCount) {
        return;
      }

      final latestAcceptedInfo = latestDetail.acceptedRequestInfo;
      final hasActiveAcceptedRequest =
          latestAcceptedInfo?.hasAcceptedUser == true &&
              (latestAcceptedInfo?.authenticationCode?.trim().isNotEmpty ??
                  false) &&
              (latestAcceptedInfo?.expiresAt?.trim().isNotEmpty ?? false);

      if (!hasActiveAcceptedRequest) {
        final wasReopened = normalizedStatus == 'CRIADO';
        await _leaveAcceptedView(
          _LeaveMessage(
            wasReopened
                ? 'O serviço foi cancelado e o pedido voltou para aberto.'
                : 'Pedido confirmado. Retornando para a página inicial.',
            isError: wasReopened,
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _resolvedServiceDetail = latestDetail;
        _serviceId = latestDetail.id ?? _serviceId;
        _syncAcceptedRequestInfoFromServiceDetail();
      });
      _syncRemainingAuthenticationCodeTime();

      if (_isAuthenticationCodeExpired &&
          !_isHandlingExpiration &&
          !_isSecondCallPromptOpen &&
          !_isStartDialogOpen) {
        await _handleAuthenticationCodeExpired();
      }
    } catch (_) {}
  }

  Future<void> _leaveAcceptedView([
    _LeaveMessage? leaveMessage,
    Object? mainArguments,
    String? destination,
  ]) async {
    if (_isLeavingAcceptedView) return;
    _isLeavingAcceptedView = true;

    _countdownTimer?.cancel();
    _acceptedRequestSyncTimer?.cancel();

    final serviceId = _resolvedServiceDetail?.id;
    if (serviceId != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accepted_request_info_$serviceId');
    }

    if (!mounted) return;

    if (leaveMessage != null) {
      AppSnackBar.show(context, leaveMessage.text,
          isError: leaveMessage.isError);
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      destination ?? AppRoutes.main,
      (route) => false,
      arguments: mainArguments,
    );
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
          AnimatedSideMenuOverlay(
            isOpen: _isDrawerOpen,
            onClose: _toggleDrawer,
            onWalletPressed: _openWallet,
            top: 0,
          ),
          if (_isWalletOpen)
            Positioned.fill(
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
    if (_isLoadingServiceDetail && _resolvedServiceDetail == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
        ),
      );
    }

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
              const SizedBox(height: 18),
              _buildCancelServiceButton(),
            ] else ...[
              const SizedBox(height: 12),
              _buildCalloutCard(),
              const SizedBox(height: 12),
              _buildAcceptedProviderCard(),
              const SizedBox(height: 18),
              _buildStartButton(),
              const SizedBox(height: 12),
              _buildCancelServiceButton(),
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
              offset: _isShowingDetails ? Offset.zero : const Offset(0, -0.16),
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
                  : 'Título do pedido Lorem Ipsum',
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
            : 'Preciso de um profissional para realizar a pintura de uma parede interna, com acabamento uniforme e atenção aos detalhes.',
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
      header:
          'Postado as ${_formatTime(_resolvedServiceDetail?.postedAt)} por:',
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
                  creator?.name.isNotEmpty == true
                      ? creator!.name
                      : 'Solicitante',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.preto,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                _buildRatingRow(_resolveRequesterRating(creator)),
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
    final phone =
        _formatPhoneNumber(_resolvedServiceDetail?.userCreator.phoneNumber);

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
    final acceptedUser =
        _resolvedServiceDetail?.acceptedRequestInfo?.acceptedUser;
    final acceptedName = _resolveAcceptedUserName(acceptedUser);
    final acceptedPhone = _formatPhoneNumber(
      acceptedUser?.phoneNumber ?? _acceptedUserPhone,
    );

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
                  acceptedName,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.preto,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                _buildRatingRow(_resolveAcceptedUserRating(acceptedUser)),
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

  Widget _buildRatingRow(double? rating) {
    return Row(
      children: [
        Text(
          (rating ?? 0.0).toStringAsFixed(1),
          style: const TextStyle(fontSize: 16, color: AppColors.preto),
        ),
        const SizedBox(width: 3),
        const Icon(Icons.star, size: 19, color: AppColors.preto),
      ],
    );
  }

  double? _resolveRequesterRating(UserCreator? creator) {
    if (_isRequesterView) {
      return _requesterUserRating ?? creator?.rating;
    }

    return creator?.rating;
  }

  String _resolveAcceptedUserName(UserCreator? acceptedUser) {
    final acceptedUserName = acceptedUser?.name.trim();
    if (acceptedUserName != null && acceptedUserName.isNotEmpty) {
      return acceptedUserName;
    }

    return _acceptedUserName;
  }

  double? _resolveAcceptedUserRating(UserCreator? acceptedUser) {
    return _acceptedUserRating ?? acceptedUser?.rating;
  }

  Widget _buildAuthenticationCodeCard() {
    return _InfoCard(
      headerWidget: const Row(
        children: [
          Expanded(
            child: Text(
              'Código de autenticação de início',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.preto,
              ),
            ),
          ),
          Icon(
            Icons.help,
            size: 18,
            color: AppColors.preto,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 2, left: 6, right: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _displayAuthenticationCode,
              style: const TextStyle(
                fontSize: 28,
                color: AppColors.vermelho,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!_hasAuthenticationCode) ...[
              const SizedBox(height: 6),
              const Text(
                'Código ainda não carregado do servidor.',
                style: TextStyle(
                  color: AppColors.vermelho,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              !_hasAuthenticationCodeExpiration
                  ? 'Tempo indisponível no momento.'
                  : _isAuthenticationCodeExpired
                      ? 'Tempo restante: 00:00'
                      : 'Tempo restante: $_formattedAuthenticationCodeCountdown',
              style: TextStyle(
                fontSize: 15,
                color: !_hasAuthenticationCodeExpiration ||
                        _isAuthenticationCodeExpired
                    ? AppColors.vermelho
                    : AppColors.preto,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!_hasAuthenticationCodeExpiration) ...[
              const SizedBox(height: 6),
              const Text(
                'A expiração do código ainda não foi carregada do servidor.',
                style: TextStyle(
                  color: AppColors.vermelho,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else if (_isAuthenticationCodeExpired) ...[
              const SizedBox(height: 6),
              const Text(
                'O tempo do código expirou.',
                style: TextStyle(
                  color: AppColors.vermelho,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
        onPressed: _canUseAuthenticationCode ? _openStartRequestDialog : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amareloUmPoucoEscuro,
          foregroundColor: AppColors.branco,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Iniciar pedido',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelServiceButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isCancellingService
            ? null
            : () => _openCancelAcceptedServiceFlow(),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.preto,
          foregroundColor: AppColors.branco,
          disabledForegroundColor: Colors.white54,
          side: const BorderSide(color: AppColors.vermelho, width: 2.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          _isCancellingService ? 'Cancelando serviço...' : 'Cancelar serviço',
          style: const TextStyle(
            fontSize: 20,
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
      return 'Telefone indisponível';
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

class _TimeExpiredActionDialog extends StatefulWidget {
  final Duration decisionTimeout;

  const _TimeExpiredActionDialog({
    required this.decisionTimeout,
  });

  @override
  State<_TimeExpiredActionDialog> createState() =>
      _TimeExpiredActionDialogState();
}

class _TimeExpiredActionDialogState extends State<_TimeExpiredActionDialog> {
  late final DateTime _decisionDeadline;
  Duration _remainingDecisionTime = Duration.zero;
  Timer? _decisionCountdownTimer;
  Timer? _decisionTimeoutTimer;
  bool _didSelectAction = false;

  @override
  void initState() {
    super.initState();
    _decisionDeadline = DateTime.now().add(widget.decisionTimeout);
    _remainingDecisionTime = widget.decisionTimeout;

    _decisionCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncRemainingDecisionTime();
    });
    _decisionTimeoutTimer = Timer(widget.decisionTimeout, _expireDecisionTime);
  }

  @override
  void dispose() {
    _decisionCountdownTimer?.cancel();
    _decisionTimeoutTimer?.cancel();
    super.dispose();
  }

  String get _formattedDecisionCountdown {
    final totalSeconds = (_remainingDecisionTime.inMilliseconds + 999) ~/ 1000;
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = (safeSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (safeSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _syncRemainingDecisionTime() {
    final remaining = _decisionDeadline.difference(DateTime.now());
    final safeRemaining = remaining.isNegative ? Duration.zero : remaining;

    if (!mounted) {
      _remainingDecisionTime = safeRemaining;
      return;
    }

    setState(() {
      _remainingDecisionTime = safeRemaining;
    });

    if (safeRemaining == Duration.zero) {
      _expireDecisionTime();
    }
  }

  void _expireDecisionTime() {
    _selectAction(_ExpiredCodeAction.timeout);
  }

  void _selectAction(_ExpiredCodeAction action) {
    if (_didSelectAction) return;

    _decisionCountdownTimer?.cancel();
    _decisionTimeoutTimer?.cancel();

    setState(() {
      _didSelectAction = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(action);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth < 560 ? screenWidth - 36 : 520,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.amareloUmPoucoEscuro,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_off, color: AppColors.vermelho, size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tempo esgotado',
                      style: TextStyle(
                        color: AppColors.preto,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'O código expirou. Cancele o serviço com este fornecedor ou inicie uma segunda chamada com um novo código.',
                style: TextStyle(
                  color: AppColors.preto,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.amareloUmPoucoEscuro.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.amareloUmPoucoEscuro.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_bottom,
                      color: AppColors.amareloUmPoucoEscuro,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tempo para decidir: $_formattedDecisionCountdown',
                        style: const TextStyle(
                          color: AppColors.preto,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 380;
                  final cancelButton = OutlinedButton(
                    onPressed: _didSelectAction
                        ? null
                        : () => _selectAction(
                              _ExpiredCodeAction.cancelService,
                            ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.vermelho,
                      side: const BorderSide(
                        color: AppColors.vermelho,
                        width: 1.6,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancelar serviço',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );

                  final secondCallButton = ElevatedButton(
                    onPressed: _didSelectAction
                        ? null
                        : () => _selectAction(
                              _ExpiredCodeAction.secondCall,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloUmPoucoEscuro,
                      foregroundColor: AppColors.branco,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Segunda chamada',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cancelButton,
                        const SizedBox(height: 10),
                        secondCallButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: cancelButton),
                      const SizedBox(width: 12),
                      Expanded(child: secondCallButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelServiceConfirmationDialog extends StatelessWidget {
  const _CancelServiceConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth < 560 ? screenWidth - 36 : 520,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.vermelho,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.report_problem_outlined,
                    color: AppColors.vermelho,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cancelar serviço',
                      style: TextStyle(
                        color: AppColors.preto,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Deseja cancelar o serviço com este fornecedor? O pedido voltará para a lista de pedidos em aberto.',
                style: TextStyle(
                  color: AppColors.preto,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 380;
                  final backButton = OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.preto,
                      side: const BorderSide(color: AppColors.cinza),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Voltar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );

                  final continueButton = ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vermelho,
                      foregroundColor: AppColors.branco,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        backButton,
                        const SizedBox(height: 10),
                        continueButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: backButton),
                      const SizedBox(width: 12),
                      Expanded(child: continueButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartRequestDialog extends StatefulWidget {
  final int? serviceId;
  final String authenticationCode;
  final DateTime? authenticationCodeExpiresAt;
  final Future<void> Function(int serviceId) onSuccess;

  const _StartRequestDialog({
    required this.serviceId,
    required this.authenticationCode,
    required this.authenticationCodeExpiresAt,
    required this.onSuccess,
  });

  @override
  State<_StartRequestDialog> createState() => _StartRequestDialogState();
}

class _StartRequestDialogState extends State<_StartRequestDialog> {
  late final TextEditingController _codeController;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  String? _validationMessage;
  bool _isSubmitting = false;

  bool get _hasExpiration => widget.authenticationCodeExpiresAt != null;
  bool get _isExpired => _remainingTime.inSeconds <= 0;

  String get _formattedCountdown {
    final safeSeconds =
        _remainingTime.inSeconds < 0 ? 0 : _remainingTime.inSeconds;
    final minutes = (safeSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (safeSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _syncRemainingTime();

    if (_hasExpiration && !_isExpired) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _syncRemainingTime();
        if (_isExpired) {
          _timer?.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _syncRemainingTime() {
    final expiresAt = widget.authenticationCodeExpiresAt;
    final remaining = expiresAt == null
        ? Duration.zero
        : expiresAt.difference(DateTime.now());

    setState(() {
      _remainingTime = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!_hasExpiration) {
      setState(() {
        _validationMessage =
            'A expiração do código ainda não foi carregada do servidor.';
      });
      return;
    }

    if (_isExpired) {
      setState(() {
        _validationMessage = 'O tempo do código expirou.';
      });
      return;
    }

    final serviceId = widget.serviceId;
    if (serviceId == null) {
      setState(() {
        _validationMessage = 'Serviço não encontrado.';
      });
      return;
    }

    final typedCode = _codeController.text.trim();
    if (typedCode.length != 4) {
      setState(() {
        _validationMessage = 'Informe os 4 dígitos do código.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _validationMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Usuário não autenticado.');
      }

      final response = await ApiService.put(
        '/service/startService/$serviceId',
        {'code': typedCode},
        token: token,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(_extractApiErrorMessage(response.body));
      }

      if (!mounted) return;

      Navigator.of(context).pop();
      await widget.onSuccess(serviceId);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _validationMessage = _buildStartRequestErrorMessage(error);
        _isSubmitting = false;
      });
    }
  }

  String _extractApiErrorMessage(String rawBody) {
    try {
      final decoded = json.decode(rawBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {}

    return rawBody;
  }

  String _buildStartRequestErrorMessage(Object error) {
    final rawMessage = error.toString().toLowerCase();

    if (rawMessage.contains('código de verificação expirado')) {
      return 'O tempo do código expirou.';
    }

    if (rawMessage.contains('código de verificação incorreto')) {
      return 'Código inválido.';
    }

    if (rawMessage.contains('código de verificação indisponível')) {
      return 'Esse pedido não está mais aguardando confirmação.';
    }

    return 'Não foi possível confirmar o código.';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth < 480 ? screenWidth - 40 : 420,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.amareloUmPoucoEscuro,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.pin,
                      color: AppColors.amareloUmPoucoEscuro,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Iniciar pedido',
                        style: TextStyle(
                          color: AppColors.preto,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Digite o código de autenticação de 4 dígitos.',
                  style: TextStyle(
                    color: AppColors.preto,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Código de autenticação',
                  style: TextStyle(
                    color: AppColors.preto,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 54,
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlignVertical: TextAlignVertical.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      hintText: '0000',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.cinza),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.amareloUmPoucoEscuro,
                          width: 2,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      color: AppColors.preto,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  !_hasExpiration
                      ? 'Tempo indisponível no momento.'
                      : 'Tempo restante: ${_isExpired ? '00:00' : _formattedCountdown}',
                  style: TextStyle(
                    color: !_hasExpiration || _isExpired
                        ? AppColors.vermelho
                        : AppColors.preto,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!_hasExpiration) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'A expiração do código ainda não foi carregada do servidor.',
                    style: TextStyle(
                      color: AppColors.vermelho,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else if (_isExpired) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'O tempo do código expirou.',
                    style: TextStyle(
                      color: AppColors.vermelho,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else if (_validationMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _validationMessage!,
                    style: const TextStyle(
                      color: AppColors.vermelho,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.preto,
                          side: const BorderSide(color: AppColors.cinza),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amareloUmPoucoEscuro,
                          foregroundColor: AppColors.branco,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isSubmitting ? 'Confirmando...' : 'Confirmar',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
