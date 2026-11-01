import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../modelos/camion.dart';
import '../../modelos/lectura_ubicacion.dart';
import '../../modelos/usuario.dart';
import '../../servicios/auth_servicio.dart';
import '../../servicios/flota_servicio.dart';
import '../../widgets/formato.dart';
import '../../widgets/formulario_auth.dart';

/// Pantalla principal del dueño: camiones y choferes de su flota.
/// El mapa en vivo y los avisos llegan en el paso 3.
class InicioDueno extends StatelessWidget {
  const InicioDueno({super.key, required this.usuario, required this.auth});

  final Usuario usuario;
  final AuthServicio auth;

  @override
  Widget build(BuildContext context) {
    final flota = FlotaServicio(usuario.flotaId);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: StreamBuilder<String>(
            stream: flota.nombre(),
            builder: (_, s) => Text(s.data ?? 'Mi flota'),
          ),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout),
              onPressed: auth.cerrarSesion,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.local_shipping), text: 'Camiones'),
              Tab(icon: Icon(Icons.people), text: 'Choferes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ListaCamiones(flota: flota),
            _ListaChoferes(flota: flota),
          ],
        ),
      ),
    );
  }
}

class _ListaCamiones extends StatelessWidget {
  const _ListaCamiones({required this.flota});

  final FlotaServicio flota;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _NuevoCamion(flota: flota),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agregar camión'),
      ),
      body: StreamBuilder<List<Usuario>>(
        stream: flota.choferes(),
        builder: (context, choferesSnap) {
          final choferes = choferesSnap.data ?? const <Usuario>[];
          return StreamBuilder<List<Camion>>(
            stream: flota.camiones(),
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
                  child: Text('Todavía no cargaste camiones.'),
                );
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final c in camiones)
                    _TarjetaCamion(camion: c, choferes: choferes, flota: flota),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _TarjetaCamion extends StatelessWidget {
  const _TarjetaCamion({
    required this.camion,
    required this.choferes,
    required this.flota,
  });

  final Camion camion;
  final List<Usuario> choferes;
  final FlotaServicio flota;

  @override
  Widget build(BuildContext context) {
    final asignadoValido = choferes.any((u) => u.uid == camion.choferUid)
        ? camion.choferUid
        : null;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    camion.patente,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(camion.fuente.etiqueta)),
                PopupMenuButton<String>(
                  onSelected: (_) => _confirmarBorrado(context),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'borrar', child: Text('Borrar')),
                  ],
                ),
              ],
            ),
            if (camion.descripcion.isNotEmpty) Text(camion.descripcion),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.place, size: 18),
                const SizedBox(width: 4),
                Expanded(child: Text(resumenUbicacion(camion.ultimaUbicacion))),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              // La clave fuerza a redibujar si la asignación cambia afuera.
              key: ValueKey(asignadoValido),
              initialValue: asignadoValido,
              decoration: const InputDecoration(
                labelText: 'Chofer asignado',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin chofer')),
                for (final u in choferes)
                  DropdownMenuItem(value: u.uid, child: Text(u.nombre)),
              ],
              onChanged: (uid) => ejecutarConAviso(
                context,
                () => flota.asignarChofer(camion.id, uid),
                mensajeDeError,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarBorrado(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('¿Borrar ${camion.patente}?'),
        content: const Text('Se pierde también su historial de ubicaciones.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ejecutarConAviso(
        context,
        () => flota.borrarCamion(camion.id),
        mensajeDeError,
      );
    }
  }
}

class _NuevoCamion extends StatefulWidget {
  const _NuevoCamion({required this.flota});

  final FlotaServicio flota;

  @override
  State<_NuevoCamion> createState() => _NuevoCamionState();
}

class _NuevoCamionState extends State<_NuevoCamion> {
  final _form = GlobalKey<FormState>();
  final _patente = TextEditingController();
  final _descripcion = TextEditingController();
  final _imei = TextEditingController();
  FuenteUbicacion _fuente = FuenteUbicacion.celular;

  @override
  void dispose() {
    _patente.dispose();
    _descripcion.dispose();
    _imei.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    final ok = await ejecutarConAviso(
      context,
      () => widget.flota.agregarCamion(
        patente: _patente.text,
        descripcion: _descripcion.text,
        fuente: _fuente,
        gpsImei: _fuente == FuenteUbicacion.gps ? _imei.text : null,
      ),
      mensajeDeError,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo camión'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _patente,
                decoration: const InputDecoration(labelText: 'Patente'),
                textCapitalization: TextCapitalization.characters,
                validator: requerido,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcion,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Ej: Iveco blanco',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<FuenteUbicacion>(
                initialValue: _fuente,
                decoration: const InputDecoration(labelText: 'Ubicación desde'),
                items: [
                  for (final f in FuenteUbicacion.values)
                    DropdownMenuItem(value: f, child: Text(f.etiqueta)),
                ],
                onChanged: (f) => setState(() => _fuente = f!),
              ),
              if (_fuente == FuenteUbicacion.gps) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imei,
                  decoration: const InputDecoration(
                    labelText: 'IMEI del GPS',
                    helperText: 'Viene impreso en el equipo o la caja.',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}

class _ListaChoferes extends StatelessWidget {
  const _ListaChoferes({required this.flota});

  final FlotaServicio flota;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        StreamBuilder<String?>(
          stream: flota.codigoInvitacion(),
          builder: (context, s) {
            final codigo = s.data;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.vpn_key),
                title: Text(
                  codigo ?? '…',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(letterSpacing: 4),
                ),
                subtitle: const Text(
                  'Código para tus choferes. Lo ingresan al crear su cuenta.',
                ),
                trailing: codigo == null
                    ? null
                    : IconButton(
                        tooltip: 'Copiar',
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: codigo));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código copiado')),
                          );
                        },
                      ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Usuario>>(
          stream: flota.choferes(),
          builder: (context, s) {
            if (s.hasError) return Text(mensajeDeError(s.error!));
            final choferes = s.data;
            if (choferes == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (choferes.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Todavía no se sumó ningún chofer.'),
              );
            }
            return Column(
              children: [
                for (final c in choferes)
                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(c.nombre),
                    subtitle: Text(c.email),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
