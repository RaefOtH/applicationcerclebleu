import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBeAkZy6Vby_bxul-f_fDrYEyFvahwD-NE',
    appId: '1:264600838171:web:66a9f7e0ee63578fe318be',
    messagingSenderId: '264600838171',
    projectId: 'cercle-bleu-enquetes',
    authDomain: 'cercle-bleu-enquetes.firebaseapp.com',
    storageBucket: 'cercle-bleu-enquetes.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBeAkZy6Vby_bxul-f_fDrYEyFvahwD-NE',
    appId: '1:264600838171:android:66a9f7e0ee63578fe318be',
    messagingSenderId: '264600838171',
    projectId: 'cercle-bleu-enquetes',
    storageBucket: 'cercle-bleu-enquetes.firebasestorage.app',
  );
}
