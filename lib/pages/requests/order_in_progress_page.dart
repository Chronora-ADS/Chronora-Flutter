import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../widgets/header.dart';
import '../../widgets/animated_side_menu_overlay.dart';
import '../../widgets/wallet_modal.dart';
import 'order_confirmation_page.dart';

class OrderInProgressPage extends StatefulWidget {
  final ServiceDetailModel? serviceDetail;
  final int? serviceId;

  const OrderInProgressPage({
    super.key,
    this.serviceDetail,
    this.serviceId,
  });

  @override
  State<OrderInProgressPage> createState() => _OrderInProgressPageState();
}

class _OrderInProgressPageState extends State<OrderInProgressPage> {
  static const String _orderInProgressServiceIdKey =
      'order_in_progress_service_id';

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _didLoadArguments = false;
  bool _isLoadingServiceDetail = false;
  bool _isResolvingFallbackServiceId = false;
  bool _didShowAwaitingNotification = false;

  ServiceDetailModel? _serviceDetail;
  int? _serviceId;
  int? _currentUserId;
  Timer? _syncTimer;

  bool get _isProvider =>
      _currentUserId != null &&
      _serviceDetail?.userCreator.id != null &&
      _currentUserId != _serviceDetail!.userCreator.id;

  bool get _isAwaitingConfirmation =>
      _serviceDetail?.status.trim().toUpperCase() == 'AGUARDANDO_CONFIRMACAO';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadArguments) return;
    _didLoadArguments = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is ServiceDetailModel) {
      _serviceDetail = arguments;
      _serviceId = arguments.id;
    } else if (arguments is int) {
      _serviceId = arguments;
    } else if (arguments is String) {
      _serviceId = int.tryParse(arguments);
    } else if (arguments is Map) {
      final detail = arguments['serviceDetail'];
      if (detail is ServiceDetailModel) {
        _serviceDetail = detail;
        _serviceId = detail.id;
      }
      final rawId =
          arguments['serviceId'] ?? arguments['service_id'] ?? arguments['id'];
      if (_serviceId == null) {
        if (rawId is int) {
          _serviceId = rawId;
        } else if (rawId is String) {
          _serviceId = int.tryParse(rawId);
        }
      }
    } else {
      _serviceDetail = widget.serviceDetail;
      _serviceId = widget.serviceDetail?.id ?? widget.serviceId;
    }

    if (_serviceId == null) {
      _isResolvingFallbackServiceId = true;
      _loadFallbackServiceId();
    }

    if (_serviceId != null) {
      if (_serviceDetail == null) {
        _loadServiceDetail();
      } else {
        _syncStatus();
      }
    }

    _loadCurrentUser();
    _startSync();
  }

  Future<void> _loadFallbackServiceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fallbackServiceId = prefs.getInt(_orderInProgressServiceIdKey);
      if (fallbackServiceId == null || !mounted || _serviceId != null) {
        return;
      }

      setState(() {
        _serviceId = fallbackServiceId;
      });
      await _loadServiceDetail();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingFallbackServiceId = false;
        });
      } else {
        _isResolvingFallbackServiceId = false;
      }
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _startSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _syncStatus();
    });
  }

  Future<void> _syncStatus() async {
    final id = _serviceId ?? _serviceDetail?.id;
    if (id == null || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await ApiService.get('/service/get/$id', token: token);
      if (response.statusCode != 200 || !mounted) return;

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      final updated = ServiceDetailModel.fromJson(decoded);
      final newStatus = updated.status.trim().toUpperCase();

      if (newStatus == 'CONCLUIDO' || newStatus == 'CANCELADO') {
        _syncTimer?.cancel();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.main,
          (route) => false,
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _serviceDetail = updated;
        _serviceId = updated.id ?? _serviceId;
      });

      if (newStatus == 'AGUARDANDO_CONFIRMACAO' &&
          !_didShowAwaitingNotification &&
          !_isProvider) {
        _didShowAwaitingNotification = true;
        AppSnackBar.show(
          context,
          'O prestador concluiu o serviço. Confirme para finalizar.',
        );
      }
    } catch (_) {}
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await ApiService.get('/user/get', token: token);
      if (response.statusCode != 200) return;

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      final data = decoded['user'] is Map<String, dynamic>
          ? decoded['user'] as Map<String, dynamic>
          : decoded;

      final id = data['id'];
      if (!mounted) return;
      setState(() {
        _currentUserId = id is int ? id : int.tryParse(id.toString());
      });
    } catch (_) {}
  }

  Future<void> _loadServiceDetail() async {
    final id = _serviceId;
    if (id == null || _isLoadingServiceDetail) return;

    setState(() {
      _isLoadingServiceDetail = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final response = await ApiService.get('/service/get/$id', token: token);
      if (response.statusCode != 200) return;

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) return;

      if (!mounted) return;
      setState(() {
        _serviceDetail = ServiceDetailModel.fromJson(decoded);
        _serviceId = _serviceDetail?.id ?? _serviceId;
      });
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingServiceDetail = false;
        });
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

  void _finishOrder() {
    final id = _serviceId ?? _serviceDetail?.id;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationPage(
          serviceId: id,
          isFinish: true,
          isProvider: _isProvider,
        ),
      ),
    );
  }

  void _cancelOrder() {
    final id = _serviceId ?? _serviceDetail?.id;
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationPage(
          serviceId: id,
          isFinish: false,
          isProvider: _isProvider,
        ),
      ),
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
    return Positioned(
      top: 150,
      right: 0,
      child: Image.asset(
        'assets/img/Comb3.png',
        width: 110,
        errorBuilder: (_, __, ___) => const SizedBox(),
      ),
    );
  }

  Widget _buildContent() {
    if (_serviceDetail == null &&
        (_isLoadingServiceDetail ||
            _isResolvingFallbackServiceId ||
            _serviceId != null)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Status de andamento',
          style: TextStyle(
            color: AppColors.branco,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        _buildCard(),
        const SizedBox(height: 16),
        _buildFinishButton(),
        const SizedBox(height: 12),
        _buildCancelButton(),
      ],
    );
  }

  Widget _buildCard() {
    final detail = _serviceDetail;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardImage(detail),
            _buildCardInfo(detail),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(ServiceDetailModel? detail) {
    return Stack(
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: _buildServiceImage(detail?.serviceImageUrl),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBadge('Prazo: ${_formatDate(detail?.deadline)}'),
              const SizedBox(height: 6),
              _buildBadge(_formatModality(detail?.modality)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.amareloUmPoucoEscuro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.branco,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildServiceImage(String? url) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
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
          color: AppColors.branco,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildCardInfo(ServiceDetailModel? detail) {
    return Container(
      width: double.infinity,
      color: AppColors.branco,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail?.title.isNotEmpty == true
                ? detail!.title
                : 'Título do pedido',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.preto,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Postado por ${_creatorName(detail)} as ${_formatTime(detail?.postedAt)}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textoPlaceholder,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Image.asset(
                'assets/img/CoinYellow.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.monetization_on,
                  color: AppColors.amareloUmPoucoEscuro,
                  size: 22,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${detail?.timeChronos ?? 0}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.preto,
                ),
              ),
            ],
          ),
          if (detail != null && detail.categoryEntities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: detail.categoryEntities
                  .map((cat) => _buildCategoryChip(cat.name))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.amareloUmPoucoEscuro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.back_hand, color: AppColors.branco, size: 14),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.branco,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFinishButton() {
    // Prestador: bloqueado quando ja concluiu (aguardando confirmacao do solicitante)
    // Solicitante: bloqueado enquanto prestador nao concluiu
    final bool canFinish =
        _isProvider ? !_isAwaitingConfirmation : _isAwaitingConfirmation;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canFinish ? _finishOrder : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amareloUmPoucoEscuro,
          foregroundColor: AppColors.branco,
          disabledBackgroundColor: AppColors.amareloMuitoEscura,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          _isProvider
              ? (_isAwaitingConfirmation
                  ? 'Aguardando confirmação...'
                  : 'Concluir pedido')
              : 'Finalizar pedido',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _cancelOrder,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.preto,
          foregroundColor: AppColors.branco,
          disabledForegroundColor: Colors.white38,
          side: const BorderSide(color: AppColors.branco, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Cancelar pedido',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _creatorName(ServiceDetailModel? detail) {
    final name = detail?.userCreator.name.trim();
    return (name != null && name.isNotEmpty) ? name : 'Solicitante';
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '--/--/----';
    try {
      final parts = raw.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return raw;
  }

  String _formatModality(String? modality) {
    if (modality == null || modality.isEmpty) return 'Presencial';
    final n = modality.trim().toUpperCase();
    if (n == 'REMOTO' || n == 'REMOTE') return 'A distancia';
    return 'Presencial';
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {}
    if (raw.contains('T') && raw.length >= 16) {
      return raw.split('T')[1].substring(0, 5);
    }
    return '--:--';
  }
}
