import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Logger estruturado com:
/// - Níveis: info / warn / error / fatal
/// - Sanitização automática de campos sensíveis antes de qualquer saída
/// - Formato JSON em release, texto legível em debug
class AppLogger {
  // ------------------------------------------------------------------ níveis
  static String sanitizeText(String raw) => _sanitizeString(raw);

  static void info(String action, {Map<String, dynamic>? context}) =>
      _log('INFO', action, context: context);

  static void warn(String action, {Map<String, dynamic>? context, Object? error}) =>
      _log('WARN', action, context: context, error: error);

  static void error(String action, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) =>
      _log('ERROR', action, context: context, error: error, stackTrace: stackTrace);

  static void fatal(String action, {Map<String, dynamic>? context, Object? error, StackTrace? stackTrace}) =>
      _log('FATAL', action, context: context, error: error, stackTrace: stackTrace);

  // ------------------------------------------------------------------ core
  static void _log(
    String level,
    String action, {
    Map<String, dynamic>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final entry = <String, dynamic>{
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level,
      'action': action,
      if (context != null) 'context': _sanitize(context),
      if (error != null) 'error': _sanitizeString(error.toString()),
      if (stackTrace != null) 'stackTrace': _sanitizeString(stackTrace.toString()),
    };

    if (kDebugMode) {
      final icon = switch (level) {
        'INFO' => 'ℹ',
        'WARN' => '⚠',
        'ERROR' => '✖',
        'FATAL' => '☠',
        _ => '•',
      };
      debugPrint('$icon [$level] $action${context != null ? ' | ${_sanitize(context)}' : ''}${error != null ? ' | err: ${_sanitizeString(error.toString())}' : ''}');
    } else {
      debugPrint(jsonEncode(entry));
    }
  }

  // ------------------------------------------------------------------ sanitização
  static const _sensitiveKeys = {
    'password', 'senha', 'token', 'access_token', 'refresh_token',
    'authorization', 'bearer', 'secret', 'cpf', 'document',
    'card_number', 'cardnumber', 'cvv', 'security_code',
    'fcm_token', 'fcmtoken', 'api_key', 'apikey',
  };

  static const _masked = '***';

  static Map<String, dynamic> _sanitize(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (_sensitiveKeys.contains(key.toLowerCase())) {
        return MapEntry(key, _masked);
      }
      if (value is Map<String, dynamic>) {
        return MapEntry(key, _sanitize(value));
      }
      if (value is String) {
        return MapEntry(key, _sanitizeString(value));
      }
      return MapEntry(key, value);
    });
  }

  /// Remove tokens JWT e padrões sensíveis de strings livres (ex: stack traces)
  static String _sanitizeString(String raw) {
    return raw
        // JWT: eyJ...
        .replaceAll(RegExp(r'eyJ[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+'), '***JWT***')
        // Bearer token no header
        .replaceAll(RegExp(r'Bearer\s+\S+', caseSensitive: false), 'Bearer ***')
        // CPF 000.000.000-00 ou 00000000000
        .replaceAll(RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b'), '***CPF***')
        // Cartão 16 dígitos
        .replaceAll(RegExp(r'\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b'), '***CARD***');
  }
}
