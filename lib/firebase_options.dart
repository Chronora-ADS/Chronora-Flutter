// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions não foram configurados para web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não estão disponíveis para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDc9oE3BvF6mEuyMvvWCWt_k7imgsLuI4',
    appId: '1:937877707128:android:cb716e0af530b4774d508d',
    messagingSenderId: '937877707128',
    projectId: 'chronora-solucoes',
    storageBucket: 'chronora-solucoes.firebasestorage.app',
  );
}
