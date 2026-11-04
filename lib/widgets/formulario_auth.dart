import 'package:flutter/material.dart';

/// Marco común de las pantallas de ingreso y registro.
class MarcoAuth extends StatelessWidget {
  const MarcoAuth({super.key, required this.titulo, required this.hijos});

  final String titulo;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Navigator.canPop(context) ? AppBar(title: Text(titulo)) : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final h in hijos) ...[h, const SizedBox(height: 12)],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? requerido(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Completá este campo' : null;

String? validarEmail(String? v) =>
    (v == null || !v.contains('@')) ? 'Ingresá un email válido' : null;

String? validarClave(String? v) =>
    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null;

/// Ejecuta [accion] mostrando el error en un SnackBar si falla.
Future<bool> ejecutarConAviso(
  BuildContext context,
  Future<void> Function() accion,
  String Function(Object) mensaje,
) async {
  try {
    await accion();
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje(e))));
    }
    return false;
  }
}
