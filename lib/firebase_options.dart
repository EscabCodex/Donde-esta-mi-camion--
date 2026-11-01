// Configuración de Firebase.
//
// Estos valores NO son secretos: identifican el proyecto de Firebase y la
// seguridad real está en las reglas de Firestore (firestore.rules).
//
// Mientras `firebaseConfigurado` sea false la app muestra una pantalla que
// explica que falta conectar Firebase. Ver docs/configurar-firebase.md.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Pasa a true cuando se completen los valores de abajo.
const bool firebaseConfigurado = false;

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
    apiKey: 'COMPLETAR',
    appId: 'COMPLETAR',
    messagingSenderId: 'COMPLETAR',
    projectId: 'COMPLETAR',
    authDomain: 'COMPLETAR.firebaseapp.com',
    storageBucket: 'COMPLETAR.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'COMPLETAR',
    appId: 'COMPLETAR',
    messagingSenderId: 'COMPLETAR',
    projectId: 'COMPLETAR',
    storageBucket: 'COMPLETAR.firebasestorage.app',
  );
}
