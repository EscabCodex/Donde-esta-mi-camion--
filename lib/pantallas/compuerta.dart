import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../servicios/auth_servicio.dart';
import 'auth/inicio_sesion.dart';
import 'chofer/inicio_chofer.dart';
import 'dueno/inicio_dueno.dart';

/// Decide qué pantalla mostrar según la sesión y el rol.
class Compuerta extends StatelessWidget {
  const Compuerta({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthServicio();
    return StreamBuilder<User?>(
      stream: auth.cambiosDeSesion,
      builder: (context, sesion) {
        if (sesion.connectionState == ConnectionState.waiting) {
          return const _Cargando();
        }
        final usuario = sesion.data;
        if (usuario == null) return InicioSesion(auth: auth);

        return StreamBuilder<Usuario?>(
          stream: auth.perfil(usuario.uid),
          builder: (context, perfil) {
            if (perfil.hasError) {
              return _SinPerfil(auth: auth, error: perfil.error);
            }
            if (!perfil.hasData) {
              // Recién registrado: el perfil puede tardar un instante.
              return perfil.connectionState == ConnectionState.active
                  ? _SinPerfil(auth: auth)
                  : const _Cargando();
            }
            final p = perfil.data!;
            return p.esDueno
                ? InicioDueno(usuario: p, auth: auth)
                : InicioChofer(usuario: p, auth: auth);
          },
        );
      },
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _SinPerfil extends StatelessWidget {
  const _SinPerfil({required this.auth, this.error});

  final AuthServicio auth;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error == null
                    ? 'Tu cuenta no tiene un perfil todavía.'
                    : mensajeDeError(error!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: auth.cerrarSesion,
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
