import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'pantallas/compuerta.dart';
import 'pantallas/falta_firebase.dart';
import 'ubicacion/servicio_ubicacion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (firebaseConfigurado) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await ServicioUbicacion.configurar();
  }
  runApp(const AppCamion(firebaseListo: firebaseConfigurado));
}

class AppCamion extends StatelessWidget {
  const AppCamion({super.key, required this.firebaseListo});

  final bool firebaseListo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dónde está mi camión',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: firebaseListo ? const Compuerta() : const FaltaFirebase(),
    );
  }
}
