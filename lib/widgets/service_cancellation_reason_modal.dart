import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class ServiceCancellationReasonModal extends StatefulWidget {
  final String? serviceTitle;
  final String? requesterName;

  const ServiceCancellationReasonModal({
    super.key,
    this.serviceTitle,
    this.requesterName,
  });

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
            'A justificativa deve ter no máximo $_maxLength caracteres.';
      });
      return;
    }

    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final serviceTitle = widget.serviceTitle?.trim();
    final requesterName = widget.requesterName?.trim();
    final hasServiceContext =
        (serviceTitle != null && serviceTitle.isNotEmpty) ||
            (requesterName != null && requesterName.isNotEmpty);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth < 520 ? screenWidth - 40 : 480,
          maxHeight: screenHeight - 48,
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
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Justificativa obrigatória',
                        style: TextStyle(
                          color: AppColors.preto,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Formalize o motivo do cancelamento do serviço.',
                        style: TextStyle(
                          color: AppColors.preto,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      if (hasServiceContext) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppColors.amareloClaro.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.amareloUmPoucoEscuro,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (serviceTitle != null &&
                                  serviceTitle.isNotEmpty) ...[
                                const Text(
                                  'Pedido',
                                  style: TextStyle(
                                    color: AppColors.preto,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  serviceTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.preto,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                              if (requesterName != null &&
                                  requesterName.isNotEmpty) ...[
                                if (serviceTitle != null &&
                                    serviceTitle.isNotEmpty)
                                  const SizedBox(height: 10),
                                const Text(
                                  'Cliente',
                                  style: TextStyle(
                                    color: AppColors.preto,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  requesterName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.preto,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
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
                          style: const TextStyle(color: Color(0xFF0B0C0C)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
