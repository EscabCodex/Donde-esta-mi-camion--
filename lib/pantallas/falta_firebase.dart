import 'package:flutter/material.dart';

/// Se muestra mientras no esté cargada la configuración de Firebase.
class FaltaFirebase extends StatelessWidget {
  const FaltaFirebase({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_shipping, size: 64),
              SizedBox(height: 16),
              Text(
                'Falta conectar Firebase',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Completá lib/firebase_options.dart siguiendo '
                'docs/configurar-firebase.md.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
