import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/main_page_requests_model.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/models/user_creator.dart' as detail_user;
import '../../core/services/api_service.dart';
import 'request_accepted_view.dart';
import '../../widgets/header.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';

class RequestView extends StatefulWidget {
  final int? serviceId;
  final Service?
      service; // Serviço passado da main page (opcional via construtor)

  const RequestView({super.key, this.serviceId, this.service});

  @override
  State<RequestView> createState() => _RequestViewState();
}

class _RequestViewState extends State<RequestView> {
  static const List<String> _acceptedStatuses = ['ACEITO', 'ACCEPTED'];

  ServiceDetailModel? _serviceDetail;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isOwner = false;
  int? _currentUserId;
  String? _currentUserName;
  int? _currentUserPhone;
  AcceptedRequestInfo? _acceptedRequestInfo;

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Widget _buildBackgroundImages() {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 135,
          child: Image.asset(
            'assets/img/Comb2.png',
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Image.asset(
            'assets/img/BarAscending.png',
            width: 210.47,
            height: 178.9,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 60,
          child: Image.asset(
            'assets/img/Comb3.png',
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentUserFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Usuário não autenticado');

      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode == 200) {
        final Map<String, dynamic> userData = json.decode(response.body);
        final resolvedUserData = userData['user'] is Map<String, dynamic>
            ? userData['user'] as Map<String, dynamic>
            : userData;
        setState(() {
          _currentUserId = resolvedUserData['id']; // ou userData['user']['id']
          _currentUserName = (resolvedUserData['name'] as String?)?.trim();
          _currentUserPhone = resolvedUserData['phoneNumber'] as int?;
        });
        print('Current user ID from API: $_currentUserId');
      } else {
        throw Exception('Falha ao obter dados do usuário');
      }
    } catch (e) {
      print('Erro ao obter usuário: $e');
      setState(() {
        _currentUserId = null;
        _currentUserName = null;
        _currentUserPhone = null;
      });
    }
  }

  Future<void> _loadData() async {
    await _getCurrentUserFromApi();

    int? serviceId;

    if (widget.serviceId != null) {
      serviceId = widget.serviceId;
    } else if (widget.service != null) {
      serviceId = widget.service!.id;
    } else {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Service) {
        serviceId = args.id;
      } else if (args is Map && args['service'] is Service) {
        serviceId = (args['service'] as Service).id;
      }
    }

    if (serviceId != null) {
      await _fetchServiceDetail(serviceId);
    } else {
      setState(() {
        _errorMessage = 'ID do serviço não informado na URL.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchServiceDetail(int serviceId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Usuário não autenticado');

      final response = await ApiService.get(
        '/service/get/$serviceId',
        token: token,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final detail = ServiceDetailModel.fromJson(data);
        final backendAcceptedInfo =
            detail.acceptedRequestInfo?.hasAcceptedUser == true
                ? detail.acceptedRequestInfo
                : null;
        final cachedAcceptedInfo = backendAcceptedInfo == null
            ? await _loadAcceptedRequestInfo(serviceId)
            : null;
        final acceptedInfo = backendAcceptedInfo ?? cachedAcceptedInfo;

        if (backendAcceptedInfo == null && cachedAcceptedInfo != null) {
          await _clearAcceptedRequestInfo(serviceId);
        }

        print('Current user ID: $_currentUserId');
        print('Creator ID: ${detail.userCreator.id}');

        // Verifica se o usuário atual é o dono do serviço
        final isOwner =
            detail.userCreator.id.toString() == _currentUserId?.toString();

        setState(() {
          _serviceDetail = detail;
          _isOwner = isOwner;
          _acceptedRequestInfo = acceptedInfo;
          _isLoading = false;
        });

        _handleAcceptedRequestRouting(detail, acceptedInfo);
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao carregar detalhes: $e';
        _isLoading = false;
      });
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

  Future<void> _cancelRequest() async {
    // Confirmação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text('Tem certeza que deseja cancelar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Usuário não autenticado');

      const status = "CANCELADO";

      final response = await ApiService.put(
        '/service/cancelService/${_serviceDetail!.id}',
        {'status': status},
        token: token,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        final serviceId = _serviceDetail?.id;
        if (serviceId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(_acceptedRequestStorageKey(serviceId));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido cancelado com sucesso'),
            backgroundColor: AppColors.amareloClaro,
          ),
        );
        Navigator.pop(context, true); // Retorna true para atualizar a lista
      } else {
        throw Exception('Erro ao cancelar');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _editRequest() {
    final serviceId = _serviceDetail?.id;
    if (serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel identificar o pedido para editar.'),
          backgroundColor: AppColors.vermelho,
        ),
      );
      return;
    }
    // Navega para a página de edição usando o ID na URL
    Navigator.pushNamed(
      context,
      '/request-editing/$serviceId',
    ).then((edited) {
      if (edited == true) {
        // Se editado, recarrega os detalhes
        _fetchServiceDetail(serviceId);
      }
    });
  }

  void _openRequesterAcceptedPreview() {
    final hasAcceptedRequest = _acceptedRequestInfo?.hasAcceptedUser == true;
    if (_serviceDetail == null || !hasAcceptedRequest) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('O pedido ainda nao foi aceito.'),
            backgroundColor: AppColors.vermelho,
          ),
        );
      return;
    }

    Navigator.pushNamed(
      context,
      '/request-accepted-view',
      arguments: {
        'serviceId': _serviceDetail!.id,
        'serviceDetail': _serviceDetail,
        'audience': RequestAcceptedAudience.requester,
        'acceptedUserName': _acceptedRequestInfo!.acceptedUser?.name,
        'acceptedUserPhone': _acceptedRequestInfo!.acceptedUser?.phoneNumber,
        'acceptedAt': _acceptedRequestInfo!.acceptedAt,
        'authenticationCode': _acceptedRequestInfo!.authenticationCode,
        'authenticationCodeExpiresAt': _acceptedRequestInfo!.expiresAt,
      },
    );
  }

  Future<void> _acceptRequest() async {
    final serviceDetail = _serviceDetail;
    if (serviceDetail?.id == null) return;
    final serviceId = serviceDetail!.id!;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final latestServiceDetail = await _fetchServiceDetailSnapshot(serviceId);
      final latestAcceptedInfo = latestServiceDetail?.acceptedRequestInfo;

      if (_isAcceptedByAnotherProvider(latestAcceptedInfo)) {
        _showSnackBar(
          'O pedido ja foi aceito.',
          backgroundColor: AppColors.vermelho,
        );
        _goToMainPage();
        return;
      }

      // Regra temporariamente desabilitada para permitir testes de aceite
      // simultaneo em multiplas contas/navegadores.
      // final hasAnotherAcceptedRequest = await _hasAnotherAcceptedRequest(
      //   currentServiceId: serviceId,
      // );
      // if (hasAnotherAcceptedRequest) {
      //   _showSnackBar(
      //     'Voce nao pode aceitar mais de um pedido ao mesmo tempo.',
      //     backgroundColor: AppColors.vermelho,
      //   );
      //   setState(() => _isLoading = false);
      //   return;
      // }

      final response = await ApiService.put(
        '/service/acceptService/$serviceId',
        const {},
        token: token,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(_extractApiErrorMessage(response.body));
      }

      final responseBody = response.body.trim();
      ServiceDetailModel? resolvedServiceDetail;

      if (responseBody.isNotEmpty) {
        final decoded = json.decode(responseBody);
        if (decoded is Map<String, dynamic>) {
          resolvedServiceDetail = ServiceDetailModel.fromJson(decoded);
        }
      }

      resolvedServiceDetail ??= await _fetchServiceDetailSnapshot(serviceId);

      final acceptedRequestInfo = _resolveAcceptedRequestInfo(
        resolvedServiceDetail,
      );

      await _persistAcceptedRequestInfo(serviceId, acceptedRequestInfo);

      if (!mounted) return;

      setState(() {
        _serviceDetail =
            resolvedServiceDetail ?? _serviceDetail ?? serviceDetail;
        _acceptedRequestInfo = acceptedRequestInfo;
        _isLoading = false;
      });

      Navigator.pushNamed(
        context,
        '/request-accepted-view',
        arguments: {
          'serviceId': serviceId,
          'serviceDetail':
              resolvedServiceDetail ?? _serviceDetail ?? serviceDetail,
          'audience': RequestAcceptedAudience.provider,
          'acceptedUserName': acceptedRequestInfo.acceptedUser?.name,
          'acceptedUserPhone': acceptedRequestInfo.acceptedUser?.phoneNumber,
          'acceptedAt': acceptedRequestInfo.acceptedAt,
          'authenticationCode': acceptedRequestInfo.authenticationCode,
          'authenticationCodeExpiresAt': acceptedRequestInfo.expiresAt,
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_buildAcceptRequestErrorMessage(e)),
          backgroundColor: AppColors.vermelho,
        ),
      );
    }
  }

  // ignore: unused_element
  Future<void> _changeStatusToAccepted(int serviceId, String token) async {
    Object? lastError;

    for (final _ in _acceptedStatuses) {
      try {
        final response = await ApiService.put(
          '/service/acceptService/$serviceId',
          const {},
          token: token,
        );

        if (response.statusCode == 200 || response.statusCode == 204) {
          return;
        }

        lastError = Exception('Erro ${response.statusCode}: ${response.body}');
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? Exception('Não foi possível aceitar o pedido');
  }

  Future<AcceptedRequestInfo?> _loadAcceptedRequestInfo(int serviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawValue = prefs.getString(_acceptedRequestStorageKey(serviceId));
      if (rawValue == null || rawValue.isEmpty) {
        return null;
      }

      final decoded = json.decode(rawValue);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final acceptedInfo = AcceptedRequestInfo.fromJson(decoded);
      if (!acceptedInfo.hasAcceptedUser ||
          _isAcceptedRequestExpired(acceptedInfo)) {
        await prefs.remove(_acceptedRequestStorageKey(serviceId));
        return null;
      }

      return acceptedInfo;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistAcceptedRequestInfo(
    int serviceId,
    AcceptedRequestInfo acceptedRequestInfo,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _acceptedRequestStorageKey(serviceId),
      json.encode(acceptedRequestInfo.toJson()),
    );
  }

  String _acceptedRequestStorageKey(int serviceId) =>
      'accepted_request_info_$serviceId';

  Future<void> _clearAcceptedRequestInfo(int serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_acceptedRequestStorageKey(serviceId));
  }

  bool _isAcceptedRequestExpired(AcceptedRequestInfo acceptedInfo) {
    final expiresAt = acceptedInfo.expiresAt?.trim();
    if (expiresAt == null || expiresAt.isEmpty) {
      return false;
    }

    final parsedExpiresAt = _parseBackendDateTime(expiresAt);
    return parsedExpiresAt != null && !DateTime.now().isBefore(parsedExpiresAt);
  }

  DateTime? _parseBackendDateTime(String rawDateTime) {
    try {
      final parsed = DateTime.parse(rawDateTime);
      if (parsed.isUtc || _hasExplicitTimeZone(rawDateTime)) {
        return parsed.toLocal();
      }

      return DateTime.utc(
        parsed.year,
        parsed.month,
        parsed.day,
        parsed.hour,
        parsed.minute,
        parsed.second,
        parsed.millisecond,
        parsed.microsecond,
      ).toLocal();
    } catch (_) {
      return null;
    }
  }

  bool _hasExplicitTimeZone(String value) {
    return value.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value);
  }

  Future<ServiceDetailModel?> _fetchServiceDetailSnapshot(int serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) {
      throw Exception('Usuário não autenticado');
    }

    final response = await ApiService.get(
      '/service/get/$serviceId',
      token: token,
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ${response.statusCode}: ${response.body}');
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return ServiceDetailModel.fromJson(decoded);
  }

  AcceptedRequestInfo _resolveAcceptedRequestInfo(
    ServiceDetailModel? serviceDetail,
  ) {
    final backendInfo = serviceDetail?.acceptedRequestInfo;
    if (backendInfo != null &&
        backendInfo.hasAcceptedUser &&
        (backendInfo.authenticationCode?.trim().isNotEmpty ?? false) &&
        (backendInfo.expiresAt?.trim().isNotEmpty ?? false)) {
      return backendInfo;
    }

    return AcceptedRequestInfo(
      acceptedUser: backendInfo?.acceptedUser ??
          detail_user.UserCreator(
            id: _currentUserId,
            name: (_currentUserName?.trim().isNotEmpty ?? false)
                ? _currentUserName!.trim()
                : 'Prestador',
            phoneNumber: _currentUserPhone,
          ),
      acceptedAt: backendInfo?.acceptedAt,
      authenticationCode: backendInfo?.authenticationCode,
      expiresAt: backendInfo?.expiresAt,
    );
  }

  String _buildAcceptRequestErrorMessage(Object error) {
    final rawMessage = error.toString().toLowerCase();

    if (rawMessage.contains('pedido ja foi aceito por outro usuario')) {
      return 'Erro, o pedido ja foi aceito por outro usuario.';
    }

    if (rawMessage.contains('nao pode aceitar mais de um pedido')) {
      return 'Erro, voce nao pode aceitar mais de um pedido ao mesmo tempo.';
    }

    if (rawMessage.contains('voce nao pode aceitar o proprio pedido')) {
      return 'Erro, voce nao pode aceitar o proprio pedido.';
    }

    return 'Erro ao aceitar pedido.';
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

  void _handleAcceptedRequestRouting(
    ServiceDetailModel detail,
    AcceptedRequestInfo? acceptedInfo,
  ) {
    if (!mounted || _isOwner) return;
    if (!_isAcceptedByCurrentProvider(acceptedInfo)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.requestAcceptedView,
        arguments: {
          'serviceId': detail.id,
          'serviceDetail': detail,
          'audience': RequestAcceptedAudience.provider,
          'acceptedUserName': acceptedInfo?.acceptedUser?.name,
          'acceptedUserPhone': acceptedInfo?.acceptedUser?.phoneNumber,
          'acceptedAt': acceptedInfo?.acceptedAt,
          'authenticationCode': acceptedInfo?.authenticationCode,
          'authenticationCodeExpiresAt': acceptedInfo?.expiresAt,
        },
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
    final acceptedUserId = acceptedInfo?.acceptedUser?.id;
    if (acceptedUserId == null || _currentUserId == null) {
      return false;
    }

    return acceptedUserId.toString() != _currentUserId.toString();
  }

  // ignore: unused_element
  Future<bool> _hasAnotherAcceptedRequest({
    required int currentServiceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || _currentUserId == null) {
      return false;
    }

    final response = await ApiService.get('/service/get/all', token: token);
    if (response.statusCode != 200) {
      return false;
    }

    final responseData = json.decode(response.body);
    List<dynamic> rawServices = [];

    if (responseData is List<dynamic>) {
      rawServices = responseData;
    } else if (responseData is Map<String, dynamic>) {
      if (responseData['services'] is List<dynamic>) {
        rawServices = responseData['services'] as List<dynamic>;
      } else if (responseData['data'] is List<dynamic>) {
        rawServices = responseData['data'] as List<dynamic>;
      } else if (responseData['content'] is List<dynamic>) {
        rawServices = responseData['content'] as List<dynamic>;
      }
    }

    for (final rawService in rawServices) {
      if (rawService is! Map<String, dynamic>) continue;

      final detail = ServiceDetailModel.fromJson(rawService);
      final serviceId = detail.id;
      if (serviceId == null || serviceId == currentServiceId) continue;

      if (_isAcceptedByCurrentProvider(detail.acceptedRequestInfo)) {
        return true;
      }
    }

    return false;
  }

  void _showSnackBar(
    String message, {
    required Color backgroundColor,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
  }

  void _goToMainPage() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.main);
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
              Header(onMenuPressed: _toggleDrawer),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
          if (_isDrawerOpen)
            Positioned(
              top: kToolbarHeight,
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppColors.branco),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_serviceDetail == null) {
      return const Center(
        child: Text(
          'Detalhes não disponíveis',
          style: TextStyle(color: AppColors.branco),
        ),
      );
    }

    return Container(
        child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          ),
          width: double.infinity,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Título
            Text(
              _serviceDetail!.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: const BoxDecoration(
            color: AppColors.preto,
            border: Border(
                bottom: BorderSide(
                    color: AppColors.amareloUmPoucoMaisEscuro, width: 3),
                top: BorderSide(
                    color: AppColors.amareloUmPoucoMaisEscuro, width: 3),
                left: BorderSide(
                    color: AppColors.amareloUmPoucoMaisEscuro, width: 3),
                right: BorderSide(
                    color: AppColors.amareloUmPoucoMaisEscuro, width: 3)),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12)),
          ),
          child: Column(
            children: [
              // Linha com imagem à esquerda e informações à direita
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagem
                  ClipRRect(
                    child: Container(
                      width: 200,
                      height: 113,
                      decoration: BoxDecoration(
                        color: AppColors.cinza,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _serviceDetail!.serviceImageUrl != null &&
                              _serviceDetail!.serviceImageUrl!.isNotEmpty
                          ? Image.network(
                              _serviceDetail!.serviceImageUrl!,
                              width: 160,
                              height: 90,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.cinza,
                                  child: const Icon(Icons.broken_image,
                                      size: 40, color: AppColors.cinza),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.amareloClaro),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.cinza,
                              child: const Icon(Icons.image,
                                  size: 40, color: AppColors.cinza),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Informações à direita
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Prazo
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amareloUmPoucoEscuro,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Prazo: ${_formatDate(_serviceDetail!.deadline)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.branco,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Modalidade
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.amareloUmPoucoEscuro,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _serviceDetail!.modality,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.branco,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Chronos
                        // Chronos com ícone alinhado à direita
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
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.currency_bitcoin,
                                        color: AppColors.amareloClaro,
                                        size: 20),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${_serviceDetail!.timeChronos} Chronos',
                                  style: const TextStyle(
                                    color: AppColors.amareloClaro,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child:
                    // Descrição
                    Text(
                  _serviceDetail!.description,
                  style: const TextStyle(fontSize: 16, color: AppColors.branco),
                ),
              )
            ],
          ),
        ),

        const SizedBox(height: 5),
        if (_serviceDetail!.categoryEntities.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _serviceDetail!.categoryEntities.map((cat) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.amareloClaro,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    cat.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Informações do criador em container separado
        ...[
          Container(
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
                  'Postado às ${_formatTime(_serviceDetail!.postedAt)} por:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.amareloClaro,
                      child: Text(
                        _serviceDetail!.userCreator.name.isNotEmpty
                            ? _serviceDetail!.userCreator.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: AppColors.branco),
                      ), // imagem perfil
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _serviceDetail!.userCreator.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Text(
                                // _serviceDetail!.userCreator.rating?.toStringAsFixed(1) ??
                                "5.0",
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.star,
                                  color: AppColors.amareloClaro, size: 16),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Botões de ação
        _buildActionButtons(),
      ],
    ));
  }

  // ignore: unused_element
  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cinza,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.preto),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isOwner) {
      // Botões para o criador: Editar e Cancelar (empilhados)
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _editRequest,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.amareloUmPoucoEscuro,
                side: const BorderSide(color: AppColors.amareloUmPoucoEscuro),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Editar pedido',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.branco,
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
                    color: AppColors.amareloUmPoucoEscuro, width: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'Cancelar pedido',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _openRequesterAcceptedPreview,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.amareloClaro,
                foregroundColor: AppColors.preto,
                side: const BorderSide(
                  color: AppColors.amareloUmPoucoEscuro,
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
    } else {
      // Botão para outros usuários: Aceitar
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
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}
    return date;
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '--:--';
    try {
      final parts = dateTime.split('T');
      if (parts.length > 1) {
        return parts[1].substring(0, 5); // HH:MM
      }
    } catch (_) {}
    return '--:--';
  }
}
