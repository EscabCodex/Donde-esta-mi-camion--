import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/camion.dart';
import '../modelos/lectura_ubicacion.dart';
import '../modelos/usuario.dart';

/// Datos de una flota: camiones y choferes.
class FlotaServicio {
  FlotaServicio(this.flotaId, {FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final String flotaId;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _flota =>
      _db.collection('flotas').doc(flotaId);

  CollectionReference<Map<String, dynamic>> get _camiones =>
      _flota.collection('camiones');

  Stream<String?> codigoInvitacion() =>
      _flota.snapshots().map((d) => d.data()?['codigoInvitacion'] as String?);

  Stream<String> nombre() =>
      _flota.snapshots().map((d) => d.data()?['nombre'] as String? ?? '');

  Stream<List<Camion>> camiones() => _camiones
      .orderBy('patente')
      .snapshots()
      .map((q) => q.docs.map((d) => Camion.desdeMapa(d.id, d.data())).toList());

  Stream<List<Camion>> camionesDelChofer(String choferUid) => _camiones
      .where('choferUid', isEqualTo: choferUid)
      .snapshots()
      .map((q) => q.docs.map((d) => Camion.desdeMapa(d.id, d.data())).toList());

  Stream<List<Usuario>> choferes() => _db
      .collection('usuarios')
      .where('flotaId', isEqualTo: flotaId)
      .where('rol', isEqualTo: Rol.chofer.name)
      .snapshots()
      .map(
        (q) => q.docs.map((d) => Usuario.desdeMapa(d.id, d.data())).toList(),
      );

  Future<void> agregarCamion({
    required String patente,
    required String descripcion,
    required FuenteUbicacion fuente,
    String? gpsImei,
  }) => _camiones.add({
    'patente': patente.trim().toUpperCase(),
    'descripcion': descripcion.trim(),
    'fuente': fuente.name,
    'choferUid': null,
    'gpsImei': (gpsImei?.trim().isEmpty ?? true) ? null : gpsImei!.trim(),
  });

  Future<void> asignarChofer(String camionId, String? choferUid) =>
      _camiones.doc(camionId).update({'choferUid': choferUid});

  Future<void> borrarCamion(String camionId) =>
      _camiones.doc(camionId).delete();
}
