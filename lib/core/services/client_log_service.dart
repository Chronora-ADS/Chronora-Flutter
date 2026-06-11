import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:chronora/core/api/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ClientLogService {
  static const String _relayEndpoint = '/monitoring/client-logs';

  static void initializeGlobalHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      unawaited(
        logError(
          error: details.exception,
          stackTrace: details.stack,
          source: 'flutter_error',
          context: {
            'library': details.library,
            'context': details.context?.toDescription(),
          },
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        logError(
          error: error,
          stackTrace: stack,
          source: 'platform_dispatcher',
        ),
      );
      return true;
    };
  }

  static Future<void> logError({
    required Object error,
    StackTrace? stackTrace,
    required String source,
    Map<String, dynamic>? context,
  }) async {
    final payload = {
      'level': 'error',
      'source': source,
      'message': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'platform': _platformName,
      'isReleaseMode': kReleaseMode,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      if (context != null) 'context': context,
    };

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}$_relayEndpoint'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'ClientLogService relay failed: '
          '${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('ClientLogService exception while sending log: $e');
    }
  }

  static String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
