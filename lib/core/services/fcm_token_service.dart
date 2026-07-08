import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_service.dart';
import '../utils/app_logger.dart';

class FcmTokenService {
  static Future<void> registerToken(String authToken) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Solicita permissão mas não bloqueia o registro do token caso negada
      await messaging.requestPermission();

      final fcmToken = await messaging.getToken();
      if (fcmToken == null) return;

      await ApiService.put(
        '/user/fcm-token',
        {'token': fcmToken},
        token: authToken,
      );
    } catch (e) {
      AppLogger.warn('Falha ao registrar token FCM', error: e);
    }
  }
}
