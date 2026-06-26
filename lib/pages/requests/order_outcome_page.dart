import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/utils/app_snackbar.dart';
import '../../widgets/header.dart';
import '../../widgets/animated_side_menu_overlay.dart';
import '../../widgets/wallet_modal.dart';
import 'review_page.dart';

enum OrderOutcome { concluido, cancelado }

class OrderOutcomePage extends StatefulWidget {
  final OrderOutcome outcome;
  final bool isProvider;
  final int serviceId;

  const OrderOutcomePage({
    super.key,
    required this.outcome,
    required this.isProvider,
    required this.serviceId,
  });

  @override
  State<OrderOutcomePage> createState() => _OrderOutcomePageState();
}

class _OrderOutcomePageState extends State<OrderOutcomePage> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;

  bool get _isConcluded => widget.outcome == OrderOutcome.concluido;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        _isConcluded ? 'Pedido finalizado com sucesso!' : 'Pedido cancelado.',
        isError: !_isConcluded,
      );
    });
  }

  void _toggleDrawer() => setState(() => _isDrawerOpen = !_isDrawerOpen);
  void _openWallet() => setState(() {
        _isDrawerOpen = false;
        _isWalletOpen = true;
      });
  void _closeWallet() => setState(() => _isWalletOpen = false);

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
              Expanded(child: _buildBody()),
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

  Widget _buildBody() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isConcluded
                    ? 'Pedido finalizado\ncom sucesso!'
                    : 'Pedido cancelado.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.preto,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 28),
              if (_isConcluded) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewPage(
                          serviceId: widget.serviceId,
                          isProvider: widget.isProvider,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloUmPoucoEscuro,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.isProvider
                          ? 'Avaliar solicitante'
                          : 'Avaliar prestador',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.myOrders,
                    (route) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.preto,
                    side: const BorderSide(color: AppColors.preto, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Voltar aos meus pedidos',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
