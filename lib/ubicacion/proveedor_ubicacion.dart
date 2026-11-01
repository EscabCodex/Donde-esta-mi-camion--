import '../modelos/lectura_ubicacion.dart';

/// Algo que produce posiciones de un camión.
///
/// Hoy existe [ProveedorCelular] (GPS del teléfono del chofer). Un GPS 4G
/// no corre dentro de la app: le manda sus datos a un servidor, y ese
/// servidor escribe en Firestore con el mismo formato ([LecturaUbicacion])
/// usando el mismo camino que [PublicadorUbicacion]. Por eso el lado del
/// dueño nunca necesita saber de dónde vino cada punto.
abstract class ProveedorUbicacion {
  FuenteUbicacion get fuente;

  /// Pide permisos si hace falta. Devuelve un mensaje de error o null si
  /// está todo bien.
  Future<String?> prepararse();

  /// Emite una lectura cada vez que el camión se mueve lo suficiente.
  Stream<LecturaUbicacion> lecturas();
}
