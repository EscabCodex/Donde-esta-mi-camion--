import 'dart:async';

import 'package:flutter/material.dart';

import '../../modelos/camion.dart';
import '../../modelos/lectura_ubicacion.dart';
import '../../modelos/usuario.dart';
import '../../servicios/auth_servicio.dart';
import '../../servicios/flota_servicio.dart';
import '../../ubicacion/ajustes_celular.dart';
import '../../ubicacion/proveedor_celular.dart';
import '../../ubicacion/publicador_ubicacion.dart';
import '../../ubicacion/servicio_ubicacion.dart';
import '../../widgets/formato.dart';

/// Pantalla del chofer: ve su camión y comparte la ubicación.
///
/// La ubicación se sigue mandando con la pantalla apagada y aunque se cierre
/// la app: en Android queda un aviso fijo "Compartiendo ubicación".
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
  // Fuera de Android (web) se comparte solo con la página abierta.
  late final _publicador = PublicadorUbicacion(
    flotaId: widget.flotaId,
    camionId: widget.camion.id,
  );
  final _proveedor = ProveedorCelular();
  StreamSubscription<String>? _errores;
  bool _activo = false;
  bool _ocupado = false;
  String? _error;
  bool _permisoSiempre = true;

  /// Solo preguntamos una vez por el ahorro de batería cada vez que se abre
  /// la app, para no molestar.
  static bool _yaPreguntoBateria = false;

  @override
  void initState() {
    super.initState();
    if (ServicioUbicacion.disponible) {
      _errores = ServicioUbicacion.errores().listen(
        (m) => mounted ? setState(() => _error = m) : null,
      );
      // Si la app se cerró mientras compartía, el servicio sigue andando.
      ServicioUbicacion.camionCompartido().then((camion) async {
        final siempre = await _proveedor.tienePermisoSiempre();
        if (mounted) {
          setState(() {
            _activo = camion == widget.camion.id;
            _permisoSiempre = siempre;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _errores?.cancel();
    _publicador.detener();
    super.dispose();
  }

  Future<void> _alternar() async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      if (_activo) {
        if (ServicioUbicacion.disponible) {
          await ServicioUbicacion.detener();
        } else {
          _publicador.detener();
        }
        if (mounted) setState(() => _activo = false);
        return;
      }
      await _empezar();
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _empezar() async {
    final problema = await _proveedor.prepararse();
    if (!mounted) return;
    if (problema != null) {
      setState(() => _error = problema);
      return;
    }
    await _pedirAjustesSegundoPlano();
    if (!mounted) return;
    final siempre = await _proveedor.tienePermisoSiempre();
    if (!mounted) return;
    setState(() {
      _error = null;
      _permisoSiempre = siempre;
    });
    if (ServicioUbicacion.disponible) {
      await ServicioUbicacion.iniciar(
        flotaId: widget.flotaId,
        camionId: widget.camion.id,
      );
    } else {
      _publicador.iniciar(
        _proveedor,
        alFallar: (e) {
          if (mounted) setState(() => _error = mensajeDeError(e));
        },
      );
    }
    if (mounted) setState(() => _activo = true);
  }

  /// Pide, explicando antes, lo que hace falta para que la ubicación no se
  /// corte con la pantalla apagada. Si el chofer dice que no, igual se
  /// comparte (con menos garantías).
  Future<void> _pedirAjustesSegundoPlano() async {
    if (!await _proveedor.tienePermisoSiempre()) {
      if (!mounted) return;
      final ir = await _explicar(
        titulo: 'Ubicación con la pantalla apagada',
        texto:
            'Para que el dueño vea el camión aunque apagues la pantalla, '
            'en la pantalla que se abre ahora tocá "Ubicación" (si hace '
            'falta) y elegí "Permitir todo el tiempo". Después volvé a '
            'esta app.',
      );
      if (ir) await _proveedor.pedirPermisoSiempre();
    }
    await AjustesCelular.pedirNotificaciones();
    if (!_yaPreguntoBateria && !await AjustesCelular.sinAhorroDeBateria()) {
      _yaPreguntoBateria = true;
      if (!mounted) return;
      final ir = await _explicar(
        titulo: 'Que no se corte',
        texto:
            'Algunos celulares frenan las apps para ahorrar batería y la '
            'ubicación deja de llegar. En el próximo mensaje tocá "Permitir".',
      );
      if (ir) await AjustesCelular.pedirSinAhorroDeBateria();
    }
  }

  Future<bool> _explicar({
    required String titulo,
    required String texto,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seguir'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.camion;
    final esGps = c.fuente == FuenteUbicacion.gps;
    final activo = _activo;
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
                onPressed: _ocupado ? null : _alternar,
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
            if (activo) ...[
              const SizedBox(height: 8),
              const Text(
                'Podés apagar la pantalla o usar otras apps: la ubicación se '
                'sigue mandando mientras veas el aviso "Compartiendo '
                'ubicación", aunque cierres la app. Se corta cuando tocás '
                '"Dejar de compartir" o cerrás sesión.',
              ),
              if (!_permisoSiempre) ...[
                const SizedBox(height: 8),
                Text(
                  'Ojo: no está elegido "Permitir todo el tiempo". Si la '
                  'ubicación se corta, tocá "Dejar de compartir" y volvé a '
                  'empezar para elegirlo.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
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
