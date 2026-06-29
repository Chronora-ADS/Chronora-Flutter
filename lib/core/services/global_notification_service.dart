import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_snackbar.dart';
import 'api_service.dart';

class GlobalNotificationService {
  GlobalNotificationService._();
  static final GlobalNotificationService instance =
      GlobalNotificationService._();

  Timer? _timer;
  final Set<int> _seenIds = {};
  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  static const Duration _pollInterval = Duration(seconds: 15);

  void start(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _timer?.cancel();
    _initialized = false;
    _seenIds.clear();
    _markExistingAsSeen();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _seenIds.clear();
    _initialized = false;
  }

  Future<void> _markExistingAsSeen() async {
    final notifications = await _fetchNotifications();
    if (notifications == null) return;
    for (final n in notifications) {
      final id = n['id'];
      if (id is int) _seenIds.add(id);
    }
    _initialized = true;
  }

  Future<void> _poll() async {
    if (!_initialized) return;

    final notifications = await _fetchNotifications();
    if (notifications == null) return;

    for (final n in notifications) {
      final id = n['id'];
      if (id is! int || _seenIds.contains(id)) continue;
      _seenIds.add(id);
      _showForNotification(n);
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return null;

      final response =
          await ApiService.get('/notification/get/all', token: token);
      if (response.statusCode != 200) return null;

      final decoded = json.decode(response.body);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList();
      }
      if (decoded is Map) {
        for (final key in [
          'notifications',
          'data',
          'content',
          'items',
          'result',
          'list',
        ]) {
          final value = decoded[key];
          if (value is List) {
            return value.whereType<Map<String, dynamic>>().toList();
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _showForNotification(Map<String, dynamic> n) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final message = (n['message'] as String?)?.trim() ?? '';
    final actorName = (n['actorName'] as String?)?.trim() ?? '';

    final result = _resolveMessage(message, actorName);
    if (result == null) return;

    AppSnackBar.show(
      context,
      result.$1,
      isError: result.$2,
      duration: const Duration(seconds: 4),
    );
  }

  (String, bool)? _resolveMessage(String message, String actorName) {
    // Ignorados: tratados por sincronização específica de cada tela
    if (message == 'Pedido iniciado' ||
        message == 'Segunda chamada expirada' ||
        message == 'Pedido criado' ||
        message == 'Pedido editado' ||
        message == 'Prazo do pedido renovado.' ||
        message == 'Pedido aceito') {
      return null;
    }

    if (message.startsWith('Pedido aceito por')) {
      final name = actorName.isNotEmpty ? actorName : message.replaceFirst('Pedido aceito por ', '');
      return ('Seu pedido foi aceito por $name!', false);
    }

    if (message == 'Segunda chamada iniciada.') {
      return ('Segunda chamada iniciada para o seu pedido.', false);
    }

    if (message == 'Solicitante finalizou o pedido') {
      return ('O solicitante confirmou a finalização do serviço!', false);
    }

    if (message == 'Pedido finalizado.') {
      return ('Pedido finalizado com sucesso!', false);
    }

    if (message.startsWith('Pedido cancelado por') ||
        message.startsWith('Serviço cancelado por')) {
      final name = actorName.isNotEmpty ? actorName : '';
      final suffix = name.isNotEmpty ? ' por $name.' : '.';
      return ('Pedido cancelado$suffix', true);
    }

    if (message == 'Pedido cancelado.' || message == 'Serviço cancelado') {
      return ('Um pedido foi cancelado.', true);
    }

    if (message == 'Pedido cancelado automaticamente por prazo expirado.') {
      return ('Pedido cancelado automaticamente por prazo expirado.', true);
    }

    if (message.startsWith('Prazo do pedido chegou')) {
      return ('Prazo do pedido chegou. Renove o prazo ou cancele o pedido.', true);
    }

    if (message == 'Você foi avaliado') {
      return ('Você recebeu uma nova avaliação!', false);
    }

    return null;
  }
}
