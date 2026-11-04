import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/lectura_ubicacion.dart';
import 'proveedor_ubicacion.dart';

/// Guarda las posiciones de un camión en Firestore.
///
/// Cada lectura actualiza `ultimaUbicacion` del camión (lo que ve el mapa
/// en vivo) y se agrega al historial `posiciones` (para recorridos y kms).
/// Un servidor que reciba datos de un GPS 4G debe escribir exactamente lo
/// mismo, así ambas fuentes se ven igual.
class PublicadorUbicacion {
  PublicadorUbicacion({
    required this.flotaId,
    required this.camionId,
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance;

  final String flotaId;
  final String camionId;
  final FirebaseFirestore _db;
  StreamSubscription<LecturaUbicacion>? _suscripcion;

  bool get activo => _suscripcion != null;

  DocumentReference<Map<String, dynamic>> get _camion => _db
      .collection('flotas')
      .doc(flotaId)
      .collection('camiones')
      .doc(camionId);

  Future<void> publicar(LecturaUbicacion lectura) {
    final datos = lectura.aMapa();
    final lote = _db.batch()
      ..update(_camion, {'ultimaUbicacion': datos})
      ..set(_camion.collection('posiciones').doc(), datos);
    return lote.commit();
  }

  /// Empieza a escuchar al proveedor y publicar cada lectura.
  void iniciar(
    ProveedorUbicacion proveedor, {
    void Function(Object)? alFallar,
  }) {
    detener();
    _suscripcion = proveedor.lecturas().listen(
      (l) => publicar(l).catchError((Object e) => alFallar?.call(e)),
      onError: (Object e) => alFallar?.call(e),
    );
  }

  void detener() {
    _suscripcion?.cancel();
    _suscripcion = null;
  }
}
