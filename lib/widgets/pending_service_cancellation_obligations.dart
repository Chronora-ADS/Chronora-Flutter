import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_session_service.dart';
import '../core/services/pending_service_cancellation_service.dart';
import 'service_cancellation_reason_modal.dart';

class PendingServiceCancellationObligations {
  static Future<bool> ensureCanContinue(
    BuildContext context, {
    required String actionLabel,
  }) async {
    final pending = await PendingServiceCancellationStore.getAll();
    if (pending.isEmpty) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    await _showBlockedActionDialog(
      context,
      pending: pending,
      actionLabel: actionLabel,
    );
    return false;
  }

  static Future<void> showPendingList(
    BuildContext context, {
    List<PendingServiceCancellationJustification>? pending,
  }) async {
    final pendingItems =
        pending ?? await PendingServiceCancellationStore.getAll();
    if (!context.mounted || pendingItems.isEmpty) {
      return;
    }

    if (pendingItems.length == 1) {
      await resolvePending(context, pendingItems.first);
      return;
    }

    final parentContext = context;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.amareloUmPoucoEscuro,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pendencias obrigatorias',
                            style: TextStyle(
                              color: AppColors.preto,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fechar',
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemBuilder: (_, index) {
                        final item = pendingItems[index];
                        return _PendingItemCard(
                          pending: item,
                          onResolve: () async {
                            Navigator.of(dialogContext).pop();
                            await resolvePending(parentContext, item);
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: pendingItems.length,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> resolvePending(
    BuildContext context,
    PendingServiceCancellationJustification pending,
  ) async {
    while (context.mounted) {
      final justification = await showDialog<String>(
        // ignore: use_build_context_synchronously
        context: context,
        barrierDismissible: false,
        builder: (_) => ServiceCancellationReasonModal(
          serviceTitle: pending.displayTitle,
          requesterName: pending.displayRequesterName,
        ),
      );

      if (!context.mounted) {
        return;
      }

      if (justification == null || justification.trim().isEmpty) {
        return;
      }

      final didSubmit = await _submitJustification(
        context,
        pending: pending,
        justification: justification.trim(),
      );

      if (didSubmit) {
        return;
      }
    }
  }

  static Future<bool> _submitJustification(
    BuildContext context, {
    required PendingServiceCancellationJustification pending,
    required String justification,
  }) async {
    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) {
        throw Exception('Usuario nao autenticado. Faca login novamente.');
      }

      final response = await ApiService.put(
        '/service/cancelAcceptedService/${pending.serviceId}/justification',
        {'justification': justification},
        token: token,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          ApiService.extractErrorMessage(
            response.body,
            fallback: 'Nao foi possivel registrar a justificativa.',
          ),
        );
      }

      await PendingServiceCancellationStore.remove(pending.serviceId);

      if (!context.mounted) {
        return true;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Justificativa registrada nas notificacoes.'),
            backgroundColor: Colors.green,
          ),
        );
      return true;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _friendlyErrorMessage(
                  error,
                  fallback: 'Nao foi possivel registrar a justificativa.',
                ),
              ),
              backgroundColor: AppColors.vermelho,
            ),
          );
      }
      return false;
    }
  }

  static Future<void> _showBlockedActionDialog(
    BuildContext context, {
    required List<PendingServiceCancellationJustification> pending,
    required String actionLabel,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pendencia obrigatoria'),
          content: Text(
            'Antes de $actionLabel, resolva a justificativa pendente de cancelamento de servico.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Voltar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    showPendingList(context, pending: pending);
                  }
                });
              },
              child: const Text('Ver pendencias'),
            ),
          ],
        );
      },
    );
  }

  static String _friendlyErrorMessage(
    Object error, {
    required String fallback,
  }) {
    final rawMessage = error.toString().replaceFirst(
          RegExp(r'^Exception:\s*'),
          '',
        );
    return ApiService.extractErrorMessage(rawMessage, fallback: fallback);
  }
}

class PendingServiceCancellationOverlay extends StatefulWidget {
  final Widget child;

  const PendingServiceCancellationOverlay({
    super.key,
    required this.child,
  });

  @override
  State<PendingServiceCancellationOverlay> createState() =>
      _PendingServiceCancellationOverlayState();
}

class _PendingServiceCancellationOverlayState
    extends State<PendingServiceCancellationOverlay> {
  List<PendingServiceCancellationJustification> _pending = [];

  @override
  void initState() {
    super.initState();
    PendingServiceCancellationStore.changes.addListener(_loadPending);
    _loadPending();
  }

  @override
  void dispose() {
    PendingServiceCancellationStore.changes.removeListener(_loadPending);
    super.dispose();
  }

  Future<void> _loadPending() async {
    final pending = await PendingServiceCancellationStore.getAll();
    if (!mounted) return;

    setState(() {
      _pending = pending;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_pending.isNotEmpty)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: _PendingBottomBanner(pending: _pending),
            ),
          ),
      ],
    );
  }
}

class PendingActionGate extends StatefulWidget {
  final String actionLabel;
  final Widget child;

  const PendingActionGate({
    super.key,
    required this.actionLabel,
    required this.child,
  });

  @override
  State<PendingActionGate> createState() => _PendingActionGateState();
}

class _PendingActionGateState extends State<PendingActionGate> {
  List<PendingServiceCancellationJustification> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    PendingServiceCancellationStore.changes.addListener(_loadPending);
    _loadPending();
  }

  @override
  void dispose() {
    PendingServiceCancellationStore.changes.removeListener(_loadPending);
    super.dispose();
  }

  Future<void> _loadPending() async {
    final pending = await PendingServiceCancellationStore.getAll();
    if (!mounted) return;

    setState(() {
      _pending = pending;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pending.isEmpty) {
      return widget.child;
    }

    return _PendingBlockedPage(
      actionLabel: widget.actionLabel,
      pending: _pending,
    );
  }
}

class _PendingBottomBanner extends StatelessWidget {
  final List<PendingServiceCancellationJustification> pending;

  const _PendingBottomBanner({required this.pending});

  @override
  Widget build(BuildContext context) {
    final count = pending.length;
    final message = count == 1
        ? 'Voce possui 1 pendencia obrigatoria.'
        : 'Voce possui $count pendencias obrigatorias.';

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.preto,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.amareloClaro,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.assignment_late_outlined,
              color: AppColors.amareloClaro,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.branco,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () =>
                  PendingServiceCancellationObligations.showPendingList(context,
                      pending: pending),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.preto,
                backgroundColor: AppColors.amareloClaro,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ver pendencias',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingBlockedPage extends StatelessWidget {
  final String actionLabel;
  final List<PendingServiceCancellationJustification> pending;

  const _PendingBlockedPage({
    required this.actionLabel,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.amareloUmPoucoEscuro,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    color: AppColors.amareloUmPoucoEscuro,
                    size: 38,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Antes de $actionLabel',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.preto,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Resolva a justificativa obrigatoria de cancelamento de servico para liberar esta acao.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.preto,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () =>
                        PendingServiceCancellationObligations.showPendingList(
                            context,
                            pending: pending),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amareloUmPoucoEscuro,
                      foregroundColor: AppColors.branco,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ver pendencias',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingItemCard extends StatelessWidget {
  final PendingServiceCancellationJustification pending;
  final VoidCallback onResolve;

  const _PendingItemCard({
    required this.pending,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cinza),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            pending.displayTitle,
            style: const TextStyle(
              color: AppColors.preto,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cliente: ${pending.displayRequesterName}',
            style: const TextStyle(
              color: AppColors.preto,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onResolve,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amareloUmPoucoEscuro,
                foregroundColor: AppColors.branco,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Resolver'),
            ),
          ),
        ],
      ),
    );
  }
}
