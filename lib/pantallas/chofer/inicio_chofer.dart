import 'package:flutter/material.dart';

import '../../modelos/camion.dart';
import '../../modelos/lectura_ubicacion.dart';
import '../../modelos/usuario.dart';
import '../../servicios/auth_servicio.dart';
import '../../servicios/flota_servicio.dart';
import '../../ubicacion/proveedor_celular.dart';
import '../../ubicacion/publicador_ubicacion.dart';
import '../../widgets/formato.dart';

/// Pantalla del chofer: ve su camión y comparte la ubicación.
///
/// Versión inicial: comparte mientras la app está abierta. El paso 2 suma
/// turnos y seguimiento con la pantalla apagada.
class InicioChofer extends StatelessWidget {
  const InicioChofer({super.key, required this.usuario, required this.auth});

  final Usuario usuario;
  final AuthServicio auth;

  @override
  Widget build(BuildContext context) {
    final flota = FlotaServicio(usuario.flotaId);
    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${usuario.nombre}'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: auth.cerrarSesion,
          ),
        ],
      ),
      body: StreamBuilder<List<Camion>>(
        stream: flota.camionesDelChofer(usuario.uid),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text(mensajeDeError(snap.error!)));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final camiones = snap.data!;
          if (camiones.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no tenés un camión asignado. '
                  'Pedile al dueño que te asigne uno.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final c in camiones)
                _CompartirUbicacion(
                  key: ValueKey(c.id),
                  camion: c,
                  flotaId: usuario.flotaId,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CompartirUbicacion extends StatefulWidget {
  const _CompartirUbicacion({
    super.key,
    required this.camion,
    required this.flotaId,
  });

  final Camion camion;
  final String flotaId;

  @override
  State<_CompartirUbicacion> createState() => _CompartirUbicacionState();
}

class _CompartirUbicacionState extends State<_CompartirUbicacion> {
  late final _publicador = PublicadorUbicacion(
    flotaId: widget.flotaId,
    camionId: widget.camion.id,
  );
  final _proveedor = ProveedorCelular();
  String? _error;

  @override
  void dispose() {
    _publicador.detener();
    super.dispose();
  }

  Future<void> _alternar() async {
    if (_publicador.activo) {
      setState(_publicador.detener);
      return;
    }
    final problema = await _proveedor.prepararse();
    if (!mounted) return;
    if (problema != null) {
      setState(() => _error = problema);
      return;
    }
    setState(() {
      _error = null;
      _publicador.iniciar(
        _proveedor,
        alFallar: (e) {
          if (mounted) setState(() => _error = mensajeDeError(e));
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.camion;
    final esGps = c.fuente == FuenteUbicacion.gps;
    final activo = _publicador.activo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(c.patente, style: Theme.of(context).textTheme.headlineSmall),
            if (c.descripcion.isNotEmpty) Text(c.descripcion),
            const SizedBox(height: 8),
            Text('Última ubicación: ${resumenUbicacion(c.ultimaUbicacion)}'),
            const SizedBox(height: 16),
            if (esGps)
              const Text('Este camión reporta su ubicación con un GPS 4G.')
            else
              FilledButton.icon(
                onPressed: _alternar,
                icon: Icon(activo ? Icons.stop : Icons.play_arrow),
                label: Text(
                  activo ? 'Dejar de compartir' : 'Compartir mi ubicación',
                ),
                style: activo
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      )
                    : null,
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
