import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/chronos_wallet_service.dart';
import '../../core/utils/app_snackbar.dart';
import 'buy_success_page.dart';

class PixBuyPage extends StatefulWidget {
  final int transactionId;
  final String qrCode;
  final DateTime expiresAt;
  final int chronosAmount;
  final double totalAmount;

  const PixBuyPage({
    super.key,
    required this.transactionId,
    required this.qrCode,
    required this.expiresAt,
    required this.chronosAmount,
    required this.totalAmount,
  });

  @override
  State<PixBuyPage> createState() => _PixBuyPageState();
}

class _PixBuyPageState extends State<PixBuyPage> {
  final _walletService = ChronosWalletService();
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;
  bool _expired = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.expiresAt.difference(DateTime.now());
    if (_remaining.isNegative) {
      _expired = true;
    } else {
      _startCountdown();
      _startPolling();
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = widget.expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        setState(() {
          _expired = true;
          _remaining = Duration.zero;
        });
        _pollTimer?.cancel();
        _countdownTimer?.cancel();
      } else {
        setState(() => _remaining = remaining);
      }
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_checking || _expired) return;
      _checking = true;
      try {
        final status =
            await _walletService.checkBuyPaymentStatus(widget.transactionId);
        if (status == 'PAID' && mounted) {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => BuySuccessPage(
                chronosAmount: widget.chronosAmount,
                totalAmount: widget.totalAmount,
                paymentMethod: 'PIX',
              ),
            ),
          );
        } else if (status == 'FAILED' || status == 'EXPIRED') {
          _pollTimer?.cancel();
          _countdownTimer?.cancel();
          if (mounted) setState(() => _expired = true);
        }
      } catch (_) {
        // ignora erros transientes de rede no polling
      } finally {
        _checking = false;
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _countdownText {
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.qrCode));
    AppSnackBar.show(context, 'Código PIX copiado!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      appBar: AppBar(
        backgroundColor: AppColors.preto,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.branco),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.main),
        ),
        title: const Text(
          'Pagar com PIX',
          style: TextStyle(color: AppColors.branco),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _expired ? _buildExpired() : _buildQrCode(),
        ),
      ),
    );
  }

  Widget _buildQrCode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Escaneie o QR Code para pagar',
          style: TextStyle(
            color: AppColors.branco,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.chronosAmount} Chronos — R\$ ${widget.totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(color: AppColors.cinza, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: QrImageView(
            data: widget.qrCode,
            version: QrVersions.auto,
            size: 220,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, color: AppColors.cinza, size: 16),
            const SizedBox(width: 4),
            Text(
              'Expira em $_countdownText',
              style: const TextStyle(color: AppColors.cinza, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copyCode,
            icon: const Icon(Icons.copy, color: AppColors.amareloClaro),
            label: const Text(
              'Copiar código PIX',
              style: TextStyle(color: AppColors.amareloClaro),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.amareloClaro),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Aguardando confirmação do pagamento...',
          style: TextStyle(color: AppColors.cinza, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildExpired() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code_2, color: AppColors.cinza, size: 80),
        const SizedBox(height: 16),
        const Text(
          'QR Code expirado',
          style: TextStyle(
            color: AppColors.branco,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'O tempo para pagamento expirou.\nGere um novo QR Code para tentar novamente.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.cinza),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.buyChronos),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amareloClaro,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Tentar novamente',
              style: TextStyle(color: AppColors.preto, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
