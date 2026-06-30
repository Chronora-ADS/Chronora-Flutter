import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/models/service_detail_model.dart';
import '../../core/services/auth_session_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/services/service_deadline_controller.dart';
import '../../widgets/backgrounds/background_default_widget.dart';
import '../../widgets/header.dart';
import '../../widgets/notification_card.dart';
import '../../widgets/animated_side_menu_overlay.dart';
import '../../widgets/wallet_modal.dart';
import '../requests/request_accepted_view.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const int _pageSize = 10;

  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isLoading = true;
  bool _isSubmittingDeadlineAction = false;
  int _visibleNotificationsLimit = _pageSize;
  List<NotificationEntry> _notifications = const [];
  final ServiceDeadlineController _serviceDeadlineController =
      ServiceDeadlineController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) {
        throw Exception('Usuário não autenticado.');
      }

      final response =
          await ApiService.get('/notification/get/all', token: token);
      if (response.statusCode != 200) {
        throw Exception(
          ApiService.extractErrorMessage(
            response.body,
            fallback: 'Não foi possível carregar as notificações.',
          ),
        );
      }

      final decoded = jsonDecode(response.body);
      final rawItems = _extractList(decoded);
      final notifications = rawItems
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .map(_extractNotificationMap)
          .map(NotificationEntry.fromJson)
          .toList();

      notifications.sort(
        (a, b) => b.notificationTime.compareTo(a.notificationTime),
      );

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _visibleNotificationsLimit = _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifications = const [];
        _visibleNotificationsLimit = _pageSize;
        _isLoading = false;
      });
      AppSnackBar.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      for (final key in const [
        'notifications',
        'notification',
        'data',
        'content',
        'items',
        'results',
        'result',
        'list',
      ]) {
        final value = decoded[key];
        if (value is List) {
          return value;
        }
        if (value is Map<String, dynamic>) {
          final nestedItems = _extractList(value);
          if (nestedItems.isNotEmpty) {
            return nestedItems;
          }
        }
      }
    }
    return const [];
  }

  Map<String, dynamic> _extractNotificationMap(Map<String, dynamic> item) {
    for (final key in const [
      'notification',
      'notificationEntity',
      'notificationDto',
      'data',
    ]) {
      final value = item[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.cast<String, dynamic>();
      }
    }
    return item;
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

  Future<void> _openNotification(NotificationEntry notification) async {
    final normalizedStatus =
        _normalizeServiceStatus(notification.service.status);

    if (normalizedStatus == 'EM_ANDAMENTO' ||
        normalizedStatus == 'AGUARDANDO_CONFIRMACAO') {
      await Navigator.pushNamed(
        context,
        AppRoutes.orderInProgress,
        arguments: {'serviceId': notification.service.id},
      );
      await _loadNotifications();
      return;
    }

    if (normalizedStatus == 'ACEITO' || normalizedStatus.isEmpty) {
      final didOpenResolvedRoute = await _openNotificationResolvedRoute(
        notification.service.id,
      );

      if (didOpenResolvedRoute) {
        await _loadNotifications();
        return;
      }

      if (!mounted) {
        return;
      }
    }

    final result = await Navigator.pushNamed(
      context,
      AppRoutes.requestViewWithId(notification.service.id),
    );

    if (result == true) {
      await _loadNotifications();
    }
  }

  Future<bool> _openNotificationResolvedRoute(int serviceId) async {
    try {
      final token = await AuthSessionService.getValidAccessToken();
      if (token == null) {
        return false;
      }

      final currentUserId = await _loadCurrentUserId(token);
      final response =
          await ApiService.get('/service/get/$serviceId', token: token);
      if (response.statusCode != 200) {
        return false;
      }

      final detail = ServiceDetailModel.fromJson(
        _extractServiceDetailMap(jsonDecode(response.body)),
      );
      final status = _normalizeServiceStatus(detail.status);

      if (!mounted) {
        return true;
      }

      if (status == 'EM_ANDAMENTO' || status == 'AGUARDANDO_CONFIRMACAO') {
        await Navigator.pushNamed(
          context,
          AppRoutes.orderInProgress,
          arguments: {'serviceId': serviceId},
        );
        return true;
      }

      if (status != 'ACEITO') {
        return false;
      }

      final audience = _resolveAcceptedAudience(detail, currentUserId);
      if (audience == null) {
        return false;
      }

      final acceptedInfo = detail.acceptedRequestInfo;
      await Navigator.pushNamed(
        context,
        AppRoutes.requestAcceptedView,
        arguments: {
          'serviceId': serviceId,
          'serviceDetail': detail,
          'audience': audience,
          'acceptedUserName': acceptedInfo?.acceptedUser?.name,
          'acceptedUserPhone': acceptedInfo?.acceptedUser?.phoneNumber,
          'acceptedUserRating': acceptedInfo?.acceptedUser?.rating,
          'acceptedAt': acceptedInfo?.acceptedAt,
          'authenticationCode': acceptedInfo?.authenticationCode,
          'authenticationCodeExpiresAt': acceptedInfo?.expiresAt,
          'verificationCodeCallCount': detail.verificationCodeCallCount,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  RequestAcceptedAudience? _resolveAcceptedAudience(
    ServiceDetailModel detail,
    int? currentUserId,
  ) {
    if (currentUserId == null) {
      return null;
    }

    if (detail.userCreator.id == currentUserId) {
      return RequestAcceptedAudience.requester;
    }

    final acceptedUserId = detail.acceptedRequestInfo?.acceptedUser?.id;
    if (acceptedUserId == currentUserId) {
      return RequestAcceptedAudience.provider;
    }

    return null;
  }

  Future<int?> _loadCurrentUserId(String token) async {
    final response = await ApiService.get('/user/get', token: token);
    if (response.statusCode != 200) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    final userData = decoded is Map<String, dynamic> && decoded['user'] is Map
        ? (decoded['user'] as Map).cast<String, dynamic>()
        : decoded is Map<String, dynamic>
            ? decoded
            : const <String, dynamic>{};

    return _toNullableInt(userData['id']);
  }

  Map<String, dynamic> _extractServiceDetailMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      for (final key in const ['service', 'serviceEntity', 'data', 'content']) {
        final value = decoded[key];
        if (value is Map<String, dynamic>) {
          return value;
        }
        if (value is Map) {
          return value.cast<String, dynamic>();
        }
      }
      return decoded;
    }

    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }

    return const <String, dynamic>{};
  }

  int? _toNullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _normalizeServiceStatus(String value) {
    return value.trim().toUpperCase();
  }

  Future<void> _renewDeadline(NotificationEntry notification) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 1),
    );
    final lastDate = tomorrow.add(const Duration(days: 365));
    final currentDeadline = notification.service.deadline;
    var initialDate = tomorrow;
    if (currentDeadline != null && currentDeadline.isAfter(tomorrow)) {
      initialDate =
          currentDeadline.isAfter(lastDate) ? lastDate : currentDeadline;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: tomorrow,
      lastDate: lastDate,
    );

    if (selectedDate == null) {
      return;
    }

    await _runDeadlineAction(
      action: () => _serviceDeadlineController.renewDeadline(
        serviceId: notification.service.id,
        deadline: selectedDate,
      ),
      successMessage: 'Prazo renovado com sucesso.',
    );
  }

  Future<void> _cancelDeadlineService(NotificationEntry notification) async {
    final shouldCancel = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Cancelar pedido'),
              content: const Text('Deseja cancelar este pedido?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Voltar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Cancelar pedido'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldCancel) {
      return;
    }

    await _runDeadlineAction(
      action: () => _serviceDeadlineController.cancelService(
        serviceId: notification.service.id,
      ),
      successMessage: 'Pedido cancelado com sucesso.',
    );
  }

  Future<void> _runDeadlineAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_isSubmittingDeadlineAction) {
      return;
    }

    setState(() {
      _isSubmittingDeadlineAction = true;
    });

    try {
      await action();
      if (!mounted) return;
      AppSnackBar.show(context, successMessage);
      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingDeadlineAction = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Stack(
        children: [
          Column(
            children: [
              Header(onMenuPressed: _toggleDrawer),
              Expanded(
                child: BackgroundDefaultWidget(
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.amareloClaro),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma notificação encontrada.',
          style: TextStyle(color: AppColors.branco, fontSize: 16),
        ),
      );
    }

    final visibleCount = _visibleNotificationCount;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: visibleCount + (_shouldShowLoadMoreButton ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleCount) {
          return _buildLoadMoreButton();
        }

        final notification = _notifications[index];
        final canRespondToDeadline =
            ServiceDeadlineController.canRespondToDeadline(notification);
        return GestureDetector(
          onTap: () => _openNotification(notification),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: AppColors.preto,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (notification.service.title.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    notification.service.title,
                    style: const TextStyle(
                      color: AppColors.amareloUmPoucoEscuro,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(notification.notificationTime),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                if (notification.hasDetail) ...[
                  const SizedBox(height: 12),
                  _buildNotificationDetail(notification),
                ],
                if (canRespondToDeadline) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _isSubmittingDeadlineAction
                            ? null
                            : () => _renewDeadline(notification),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amareloClaro,
                          foregroundColor: AppColors.preto,
                        ),
                        child: const Text('Renovar prazo'),
                      ),
                      OutlinedButton(
                        onPressed: _isSubmittingDeadlineAction
                            ? null
                            : () => _cancelDeadlineService(notification),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('Cancelar pedido'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationDetail(NotificationEntry notification) {
    final actorLabel = _formatActorLabel(notification);
    final detailTitle = notification.isServiceCancellationJustification
        ? 'Justificativa do cancelamento'
        : 'Detalhes';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.amareloClaro.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.amareloUmPoucoEscuro.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detailTitle,
            style: const TextStyle(
              color: AppColors.preto,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (actorLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              actorLabel,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            notification.detail,
            style: const TextStyle(
              color: AppColors.preto,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  String _formatActorLabel(NotificationEntry notification) {
    final actorName = notification.actorName.trim();
    final actorRole = notification.actorRole.trim();

    if (actorName.isEmpty && actorRole.isEmpty) {
      return '';
    }

    if (actorName.isEmpty) {
      return 'Cancelado por: $actorRole';
    }

    if (actorRole.isEmpty) {
      return 'Cancelado por: $actorName';
    }

    return 'Cancelado por: $actorName ($actorRole)';
  }

  int get _visibleNotificationCount {
    return math.min(_visibleNotificationsLimit, _notifications.length);
  }

  bool get _shouldShowLoadMoreButton {
    return _visibleNotificationCount < _notifications.length;
  }

  void _loadMoreNotifications() {
    if (!_shouldShowLoadMoreButton) {
      return;
    }

    setState(() {
      _visibleNotificationsLimit = math.min(
        _visibleNotificationsLimit + _pageSize,
        _notifications.length,
      );
    });
  }

  Widget _buildLoadMoreButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loadMoreNotifications,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.branco,
          foregroundColor: AppColors.preto,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'Carregar mais',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
