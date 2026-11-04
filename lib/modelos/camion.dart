import 'lectura_ubicacion.dart';

/// Camión guardado en `flotas/{flotaId}/camiones/{id}`.
class Camion {
  const Camion({
    required this.id,
    required this.patente,
    required this.descripcion,
    required this.fuente,
    this.choferUid,
    this.gpsImei,
    this.ultimaUbicacion,
  });

  final String id;
  final String patente;
  final String descripcion;

  /// De dónde se espera que llegue la ubicación de este camión.
  final FuenteUbicacion fuente;

  /// Chofer asignado (solo él puede reportar ubicación desde el celular).
  final String? choferUid;

  /// Identificador del rastreador, cuando la fuente es GPS 4G.
  final String? gpsImei;

  final LecturaUbicacion? ultimaUbicacion;

  factory Camion.desdeMapa(String id, Map<String, dynamic> datos) {
    final ultima = datos['ultimaUbicacion'];
    return Camion(
      id: id,
      patente: datos['patente'] as String? ?? '',
      descripcion: datos['descripcion'] as String? ?? '',
      fuente: FuenteUbicacion.desdeTexto(datos['fuente'] as String?),
      choferUid: datos['choferUid'] as String?,
      gpsImei: datos['gpsImei'] as String?,
      ultimaUbicacion: ultima is Map<String, dynamic>
          ? LecturaUbicacion.desdeMapa(ultima)
          : null,
    );
  }

  Map<String, dynamic> aMapa() => {
    'patente': patente,
    'descripcion': descripcion,
    'fuente': fuente.name,
    'choferUid': choferUid,
    'gpsImei': gpsImei,
  };
}
