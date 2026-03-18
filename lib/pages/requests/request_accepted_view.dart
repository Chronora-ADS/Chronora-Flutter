import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/services/api_service.dart';
import '../../widgets/header.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';

class RequestAcceptedView extends StatefulWidget {
  final ServiceDetailModel? serviceDetail;

  const RequestAcceptedView({super.key, this.serviceDetail});

  @override
  State<RequestAcceptedView> createState() => _RequestAcceptedViewState();
}

class _RequestAcceptedViewState extends State<RequestAcceptedView> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isShowingDetails = false;
  bool _didLoadArguments = false;
  ServiceDetailModel? _resolvedServiceDetail;
  final GlobalKey _requestCardKey = GlobalKey();
  double _requestCardHeight = 260;
  String _acceptedUserName = 'Prestador';
  int? _acceptedUserPhone;
  final DateTime _acceptedAt = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadArguments) return;
    _didLoadArguments = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is ServiceDetailModel) {
      _resolvedServiceDetail = arguments;
    } else {
      _resolvedServiceDetail = widget.serviceDetail;
    }

    _loadAcceptedUser();
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
      if (!mounted) return;

      setState(() {
        final name = (userData['name'] as String?)?.trim();
        _acceptedUserName = name != null && name.isNotEmpty ? name : _acceptedUserName;
        _acceptedUserPhone = userData['phoneNumber'] as int?;
      });
    } catch (_) {}
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
            const SizedBox(height: 12),
            _buildCalloutCard(),
            const SizedBox(height: 12),
            _buildAcceptedProviderCard(),
            const SizedBox(height: 18),
            _buildStartButton(),
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
        borderRadius: BorderRadius.circular(14),
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
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            decoration: const BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Text(
              serviceDetail?.title.isNotEmpty == true
                  ? serviceDetail!.title
                  : 'Título do pedido Lorem Ipsum',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.preto,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.preto,
              border: Border(
                left: BorderSide(color: AppColors.amareloUmPoucoEscuro, width: 3),
                right: BorderSide(color: AppColors.amareloUmPoucoEscuro, width: 3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    height: 140,
                    color: AppColors.branco,
                    child: _buildServiceImage(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
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
      header: 'Postado às ${_formatTime(_resolvedServiceDetail?.postedAt)} por:',
      child: Row(
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
                  'Antes de aceitar o\npedido,contate o solicitante\npelo telefone:',
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
              Row(
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
                  const Icon(Icons.phone_in_talk, color: AppColors.preto, size: 24),
                ],
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
      header: 'Aceito às ${_formatTimeFromDateTime(_acceptedAt)} por:',
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
                    const Icon(Icons.phone_in_talk, color: AppColors.preto, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        onPressed: () {},
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
    return Image.asset(
      'assets/img/Paintbrush.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.image,
        color: AppColors.cinza,
        size: 56,
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
    if (normalized == 'remote' || normalized == 'remoto' || normalized == 'à distância') {
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

    final normalized = digits.length > 11 ? digits.substring(digits.length - 11) : digits;
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
        const SizedBox(height: 10),
        _buildChip(modality),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/img/CoinYellow.png',
              width: 34,
              height: 34,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.monetization_on,
                color: AppColors.amareloMuitoEscura,
                size: 30,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$timeChronos Chronos',
                maxLines: 2,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.amareloClaro,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.amareloMuitoEscura,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.branco,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String header;
  final Widget child;

  const _InfoCard({
    required this.header,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinza, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
