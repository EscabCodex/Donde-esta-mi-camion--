// Configuración de Firebase.
//
// Estos valores NO son secretos: identifican el proyecto de Firebase y la
// seguridad real está en las reglas de Firestore (firestore.rules).
//
// Mientras `firebaseConfigurado` sea false la app muestra una pantalla que
// explica que falta conectar Firebase. Ver docs/configurar-firebase.md.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Proyecto Firebase: donde-esta-mi-camion-626b5.
const bool firebaseConfigurado = true;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Por ahora la app solo funciona en Android y web.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC1SuID2-wvlLoAUGmZNWsVQ0-tnXXNapI',
    appId: '1:996549075626:web:57866fe4d561d07097e6d3',
    messagingSenderId: '996549075626',
    projectId: 'donde-esta-mi-camion-626b5',
    authDomain: 'donde-esta-mi-camion-626b5.firebaseapp.com',
    storageBucket: 'donde-esta-mi-camion-626b5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDkcdLhnqN-04ron8VhsWynlfRTmZz5N9Q',
    appId: '1:996549075626:android:f42599c1f094719397e6d3',
    messagingSenderId: '996549075626',
    projectId: 'donde-esta-mi-camion-626b5',
    storageBucket: 'donde-esta-mi-camion-626b5.firebasestorage.app',
  );
}
