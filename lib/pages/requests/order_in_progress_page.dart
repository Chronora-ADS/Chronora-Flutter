import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/services/api_service.dart';
import '../../widgets/header.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';

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
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _didLoadArguments = false;
  bool _isLoadingServiceDetail = false;
  bool _isFinishing = false;
  bool _isCancelling = false;

  ServiceDetailModel? _serviceDetail;
  int? _serviceId;
  int? _currentUserId;

  bool get _isProvider =>
      _currentUserId != null &&
      _serviceDetail?.userCreator.id != null &&
      _currentUserId != _serviceDetail!.userCreator.id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadArguments) return;
    _didLoadArguments = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is ServiceDetailModel) {
      _serviceDetail = arguments;
      _serviceId = arguments.id;
    } else if (arguments is Map) {
      final detail = arguments['serviceDetail'];
      if (detail is ServiceDetailModel) {
        _serviceDetail = detail;
        _serviceId = detail.id;
      }
      final rawId = arguments['serviceId'];
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

    if (_serviceDetail == null && _serviceId != null) {
      _loadServiceDetail();
    }

    _loadCurrentUser();
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

  Future<void> _finishOrder() async {
    final id = _serviceId ?? _serviceDetail?.id;
    if (id == null || _isFinishing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _FinishOrderDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isFinishing = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Usuario nao autenticado.');

      final response = await ApiService.put(
        '/service/finishService/$id',
        const {},
        token: token,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          ApiService.extractErrorMessage(
            response.body,
            fallback: 'Nao foi possivel finalizar o pedido.',
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pedido finalizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''));
    } finally {
      if (mounted) {
        setState(() {
          _isFinishing = false;
        });
      }
    }
  }

  Future<void> _cancelOrder() async {
    final id = _serviceId ?? _serviceDetail?.id;
    if (id == null || _isCancelling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CancelOrderDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Usuario nao autenticado.');

      final response = await ApiService.put(
        '/service/cancelService/$id',
        const {},
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pedido cancelado.'),
            backgroundColor: AppColors.vermelho,
          ),
        );

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.main,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''));
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ApiService.extractErrorMessage(message,
                fallback: 'Ocorreu um erro inesperado.'),
          ),
          backgroundColor: AppColors.vermelho,
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
          if (_isDrawerOpen)
            Positioned(
              top: kToolbarHeight * 1.5,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppColors.preto.withValues(alpha: 0.5),
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
    if (_isLoadingServiceDetail && _serviceDetail == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
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
        const SizedBox(height: 24),
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
                : 'Titulo do pedido',
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isFinishing || _isCancelling) ? null : _finishOrder,
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
          _isFinishing ? 'Finalizando...' : (_isProvider ? 'Concluir' : 'Finalizar pedido'),
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
        onPressed: (_isFinishing || _isCancelling) ? null : _cancelOrder,
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
        child: Text(
          _isCancelling ? 'Cancelando...' : 'Cancelar pedido',
          style: const TextStyle(
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

class _FinishOrderDialog extends StatelessWidget {
  const _FinishOrderDialog();

  @override
  Widget build(BuildContext context) {
    return _ActionDialog(
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
      title: 'Finalizar pedido',
      message:
          'Confirma que o servico foi concluido? Esta acao nao pode ser desfeita.',
      confirmLabel: 'Finalizar',
      confirmColor: Colors.green,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
  }
}

class _CancelOrderDialog extends StatelessWidget {
  const _CancelOrderDialog();

  @override
  Widget build(BuildContext context) {
    return _ActionDialog(
      icon: Icons.report_problem_outlined,
      iconColor: AppColors.vermelho,
      title: 'Cancelar pedido',
      message:
          'Deseja cancelar este pedido em andamento? O pedido sera marcado como cancelado.',
      confirmLabel: 'Cancelar pedido',
      confirmColor: AppColors.vermelho,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
  }
}

class _ActionDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ActionDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
    required this.onCancel,
  });

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
            border: Border.all(color: AppColors.cinza, width: 1.5),
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
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.preto,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.preto,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 360;

                  final backBtn = OutlinedButton(
                    onPressed: onCancel,
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

                  final confirmBtn = ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: AppColors.branco,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        backBtn,
                        const SizedBox(height: 10),
                        confirmBtn,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: backBtn),
                      const SizedBox(width: 12),
                      Expanded(child: confirmBtn),
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
