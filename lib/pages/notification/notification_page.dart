// notification_page.dart

import 'dart:convert';
import 'package:chronora/core/constants/app_routes.dart';
import 'package:chronora/widgets/notification_card.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../widgets/header.dart';
import '../../../widgets/side_menu.dart';
import '../../../widgets/wallet_modal.dart';
import '../../../core/services/api_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _notificationState createState() => _notificationState();
}

class _notificationState extends State<NotificationPage> {
  bool _isDrawerOpen = false;
  bool _isWalletOpen = false;
  bool _isLoading = true;
  List<NotificationCard> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        _showError('Usuário não autenticado');
        setState(() => _isLoading = false);
        return;
      }

      final response = await ApiService.get('/notification/get/all', token: token);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
        final notifications = data.map((json) => NotificationCard.fromJson(json)).toList();
        notifications.sort((a, b) => b.notificationTime.compareTo(a.notificationTime));
        _notifications = notifications;
        _isLoading = false;
      });
      } else {
        _showError('Erro ao carregar notificações (${response.statusCode})');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Erro de conexão: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _toggleDrawer() => setState(() => _isDrawerOpen = !_isDrawerOpen);
  void _openWallet() => setState(() {
    _isDrawerOpen = false;
    _isWalletOpen = true;
  });
  void _closeWallet() => setState(() => _isWalletOpen = false);

  // Navegação para o serviço específico usando o ID na URL
  void _onNotificationTap(NotificationCard notification) async {
    final result = await Navigator.pushNamed(
      context,
      '${AppRoutes.requestView}/${notification.service.id}',
    );

    // Opcional: recarregar notificações se a tela retornou true (indicando edição)
    if (result == true) {
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0C0C),
      body: Stack(
        children: [
          _buildBackgroundImages(),
          Column(
            children: [
              Header(onMenuPressed: _toggleDrawer),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
          if (_isDrawerOpen)
            Positioned(
              top: kToolbarHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
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
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
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

  Widget _buildBackgroundImages() {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 135,
          child: Image.asset(
            'assets/img/Comb2.png',
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: Image.asset(
            'assets/img/BarAscending.png',
            width: 210.47,
            height: 178.9,
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 60,
          child: Image.asset(
            'assets/img/Comb3.png',
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.white54),
            SizedBox(height: 16),
            Text(
              'Nenhuma notificação encontrada',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationCard notification) {
    final formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(notification.notificationTime);

    return GestureDetector(
      onTap: () => _onNotificationTap(notification), // Card inteiro clicável
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE9EAEC),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B0C0C),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Pedido: ',
                  style: TextStyle(color: Colors.black87),
                ),
                Text(
                  notification.service.title,
                  style: const TextStyle(
                    color: Color(0xFFC29503),
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedTime,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
