import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_service.dart';

class FcmTokenService {
  static Future<void> registerToken(String authToken) async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      final fcmToken = await messaging.getToken();
      if (fcmToken == null) return;

      await ApiService.put(
        '/user/fcm-token',
        {'token': fcmToken},
        token: authToken,
      );
    } catch (_) {
      // Falha silenciosa — não bloqueia o fluxo de login
    }
  }
}
