import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ServiceCancellationReasonModal extends StatefulWidget {
  const ServiceCancellationReasonModal({super.key});

  @override
  State<ServiceCancellationReasonModal> createState() =>
      _ServiceCancellationReasonModalState();
}

class _ServiceCancellationReasonModalState
    extends State<ServiceCancellationReasonModal> {
  static const int _maxLength = 1000;

  final TextEditingController _reasonController = TextEditingController();
  final ScrollController _textScrollController = ScrollController();
  String? _validationMessage;

  @override
  void dispose() {
    _textScrollController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() {
        _validationMessage = 'Informe a justificativa do cancelamento.';
      });
      return;
    }

    if (reason.length > _maxLength) {
      setState(() {
        _validationMessage =
            'A justificativa deve ter no maximo $_maxLength caracteres.';
      });
      return;
    }

    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth < 520 ? screenWidth - 40 : 480,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.branco,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.amareloUmPoucoEscuro,
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.amareloClaro,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Justificativa obrigatoria',
                      style: TextStyle(
                        color: AppColors.preto,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Formalize o motivo do cancelamento do servico.',
                      style: TextStyle(
                        color: AppColors.preto,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Justificativa',
                      style: TextStyle(
                        color: AppColors.preto,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: TextField(
                        controller: _reasonController,
                        scrollController: _textScrollController,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        maxLength: _maxLength,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: InputDecoration(
                          hintText: 'Descreva o ocorrido...',
                          counterText: '',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.cinza,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.amareloUmPoucoEscuro,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_validationMessage != null) ...[
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
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amareloUmPoucoEscuro,
                          foregroundColor: AppColors.branco,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Enviar justificativa',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
