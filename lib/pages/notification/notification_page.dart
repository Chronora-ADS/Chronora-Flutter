import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/auth_session_service.dart';
import '../../widgets/backgrounds/background_default_widget.dart';
import '../../widgets/header.dart';
import '../../widgets/notification_card.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/wallet_modal.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isLoading = true;
  List<NotificationEntry> _notifications = const [];

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
        throw Exception('Usuario nao autenticado.');
      }

      final response = await ApiService.get('/notification/get/all', token: token);
      if (response.statusCode != 200) {
        throw Exception(
          ApiService.extractErrorMessage(
            response.body,
            fallback: 'Nao foi possivel carregar as notificacoes.',
          ),
        );
      }

      final decoded = jsonDecode(response.body);
      final rawItems = _extractList(decoded);
      final notifications = rawItems
          .map(
            (item) => NotificationEntry.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .toList()
        ..sort(
          (a, b) => b.notificationTime.compareTo(a.notificationTime),
        );

      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _notifications = const [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['content'] ?? decoded['notifications'];
      if (data is List) {
        return data;
      }
    }
    return const [];
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
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.requestViewWithId(notification.service.id),
    );

    if (result == true) {
      await _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.preto,
      body: Stack(
        children: [
          Column(
            children: [
              Header(onMenuPressed: _toggleDrawer),
              Expanded(
                child: BackgroundDefaultWidget(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
          if (_isDrawerOpen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    SizedBox(
                      width: screenWidth * 0.6,
                      child: SafeArea(
                        top: true,
                        bottom: false,
                        child: SideMenu(onWalletPressed: _openWallet),
                      ),
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
          'Nenhuma notificacao encontrada.',
          style: TextStyle(color: AppColors.branco, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
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
                const SizedBox(height: 8),
                Text(
                  'Pedido: ${notification.service.title}',
                  style: const TextStyle(
                    color: AppColors.amareloUmPoucoEscuro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDateTime(notification.notificationTime),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
