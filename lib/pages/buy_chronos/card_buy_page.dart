import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/chronos_wallet_service.dart';
import '../../core/utils/app_snackbar.dart';
import 'buy_success_page.dart';

class CardBuyPage extends StatefulWidget {
  final int chronosAmount;
  final double totalAmount;

  const CardBuyPage({
    super.key,
    required this.chronosAmount,
    required this.totalAmount,
  });

  @override
  State<CardBuyPage> createState() => _CardBuyPageState();
}

class _CardBuyPageState extends State<CardBuyPage> {
  final _formKey = GlobalKey<FormState>();
  final _walletService = ChronosWalletService();

  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final expiry = _expiryController.text.split('/');
      final month = expiry[0].trim();
      final year = expiry[1].trim();

      final tokenResult = await _walletService.tokenizeCard(
        cardNumber: _cardNumberController.text,
        expirationMonth: month,
        expirationYear: year,
        securityCode: _cvvController.text,
        cardholderName: _nameController.text.trim(),
        docNumber: _cpfController.text,
      );

      final result = await _walletService.createCardBuyPayment(
        chronosAmount: widget.chronosAmount,
        cardToken: tokenResult.token,
        cardPaymentMethodId: tokenResult.paymentMethodId,
        payerDocNumber: _cpfController.text.replaceAll(RegExp(r'\D'), ''),
      );

      if (!mounted) return;

      if (result.status == 'PAID') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BuySuccessPage(
              chronosAmount: widget.chronosAmount,
              totalAmount: widget.totalAmount,
              paymentMethod: 'Cartão de Crédito',
            ),
          ),
        );
      } else {
        if (mounted) AppSnackBar.show(context, 'Pagamento em processamento. Aguarde a confirmação.');
      }
    } catch (e) {
      if (mounted) AppSnackBar.show(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      appBar: AppBar(
        backgroundColor: AppColors.preto,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.branco),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pagar com Cartão',
            style: TextStyle(color: AppColors.branco)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummary(),
              const SizedBox(height: 24),
              _buildCardPreview(),
              const SizedBox(height: 24),
              _buildField(
                controller: _cardNumberController,
                label: 'Número do cartão',
                hint: '0000 0000 0000 0000',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                  LengthLimitingTextInputFormatter(19),
                ],
                validator: (v) {
                  final digits = v?.replaceAll(' ', '') ?? '';
                  if (digits.length < 13) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _expiryController,
                      label: 'Validade',
                      hint: 'MM/AA',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ExpiryFormatter(),
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: (v) {
                        if (v == null || v.length < 5) return 'Inválida';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildField(
                      controller: _cvvController,
                      label: 'CVV',
                      hint: '123',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (v) {
                        if ((v?.length ?? 0) < 3) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _nameController,
                label: 'Nome no cartão',
                hint: 'NOME SOBRENOME',
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  if ((v?.trim().length ?? 0) < 3) return 'Nome inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _cpfController,
                label: 'CPF do titular',
                hint: '000.000.000-00',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CpfFormatter(),
                  LengthLimitingTextInputFormatter(14),
                ],
                validator: (v) {
                  final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                  if (digits.length != 11) return 'CPF inválido';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amareloClaro,
                    disabledBackgroundColor:
                        AppColors.amareloClaro.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          'Pagar R\$ ${widget.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.preto,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amareloClaro, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/img/Coin.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on,
                      color: AppColors.amareloClaro, size: 20)),
              const SizedBox(width: 8),
              Text(
                '${widget.chronosAmount} Chronos',
                style: const TextStyle(
                    color: AppColors.branco,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ],
          ),
          Text(
            'R\$ ${widget.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
                color: AppColors.amareloClaro,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      width: double.infinity,
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.credit_card, color: AppColors.amareloClaro, size: 28),
          ValueListenableBuilder(
            valueListenable: _cardNumberController,
            builder: (_, __, ___) {
              final text = _cardNumberController.text.isEmpty
                  ? '**** **** **** ****'
                  : _cardNumberController.text.padRight(19, '*');
              return Text(
                text,
                style: const TextStyle(
                    color: AppColors.branco,
                    fontSize: 16,
                    letterSpacing: 2,
                    fontFamily: 'monospace'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(color: AppColors.branco),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.cinza),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.cinza.withValues(alpha: 0.5)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.amareloClaro, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length >= 3) {
      final text = '${digits.substring(0, 2)}/${digits.substring(2)}';
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    return newValue;
  }
}

class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
