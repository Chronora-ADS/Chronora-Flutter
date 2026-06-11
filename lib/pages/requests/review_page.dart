import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/main_page_requests_model.dart';
import '../../core/services/api_service.dart';
import '../../widgets/header.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';

class ReviewPage extends StatefulWidget {
  final int serviceId;
  final bool isProvider;

  const ReviewPage({
    super.key,
    required this.serviceId,
    required this.isProvider,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isLoadingService = true;
  bool _isSubmitting = false;
  int _selectedRating = 0;
  String? _errorMessage;
  Service? _service;

  void _toggleDrawer() => setState(() => _isDrawerOpen = !_isDrawerOpen);
  void _openWallet() => setState(() {
        _isDrawerOpen = false;
        _isWalletOpen = true;
      });
  void _closeWallet() => setState(() => _isWalletOpen = false);

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  Future<void> _loadService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Usuario nao autenticado.');

      final response = await ApiService.get(
        '/service/get/${widget.serviceId}',
        token: token,
      );

      if (!mounted) return;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Nao foi possivel carregar os dados do pedido.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        _service = Service.fromJson(json);
        _isLoadingService = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        _isLoadingService = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_selectedRating == 0) {
      setState(() => _errorMessage = 'Selecione uma nota antes de enviar.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('Usuario nao autenticado.');

      final response = await ApiService.post(
        '/review/submit/${widget.serviceId}',
        {'rating': _selectedRating},
        token: token,
      );

      if (!mounted) return;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          ApiService.extractErrorMessage(
            response.body,
            fallback: 'Nao foi possivel enviar a avaliacao.',
          ),
        );
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.myOrders,
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              if (_errorMessage != null) _buildErrorBanner(),
              Expanded(child: _buildBody()),
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

  Widget _buildErrorBanner() {
    return Container(
      color: AppColors.vermelho,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingService) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
        ),
      );
    }

    if (_service == null) {
      return Center(
        child: Text(
          'Nao foi possivel carregar o pedido.',
          style: TextStyle(
            color: AppColors.branco.withValues(alpha: 0.7),
            fontSize: 15,
          ),
        ),
      );
    }

    final reviewee = widget.isProvider
        ? _service!.userCreator
        : _service!.userAccepted;

    if (reviewee == null) {
      return Center(
        child: Text(
          'Nao foi possivel identificar o usuario a ser avaliado.',
          style: TextStyle(
            color: AppColors.branco.withValues(alpha: 0.7),
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: BorderRadius.circular(16),
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
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.preto,
                        fontSize: 17,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'Como foi o serviço com o '),
                        TextSpan(
                          text: reviewee.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const TextSpan(text: '?'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRating = index + 1),
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.amareloUmPoucoEscuro,
                            size: 44,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 1,
                    color: const Color(0xFFE0E0E0),
                  ),
                  const SizedBox(height: 20),
                  _buildRevieweeInfo(reviewee),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amareloUmPoucoEscuro,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.amareloUmPoucoEscuro.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Enviar avaliação',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevieweeInfo(dynamic reviewee) {
    final name = (reviewee.name as String?) ?? '';
    final phone = reviewee.phoneNumber as int?;
    final rating = reviewee.rating as double?;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.amareloUmPoucoEscuro,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.preto,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rating != null) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.star, color: Color(0xFFFFA000), size: 16),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.preto,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
              if (phone != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Color(0xFF555555), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatPhone(phone),
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatPhone(int phone) {
    final raw = phone.toString();
    if (raw.length == 13 && raw.startsWith('55')) {
      final area = raw.substring(2, 4);
      final number = raw.substring(4);
      final prefix = number.substring(0, number.length - 4);
      final suffix = number.substring(number.length - 4);
      return '+55 $area $prefix-$suffix';
    }
    if (raw.length == 11) {
      final area = raw.substring(0, 2);
      final number = raw.substring(2);
      final prefix = number.substring(0, number.length - 4);
      final suffix = number.substring(number.length - 4);
      return '($area) $prefix-$suffix';
    }
    return raw;
  }
}
