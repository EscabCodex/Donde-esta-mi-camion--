import 'package:geolocator/geolocator.dart';

import '../modelos/lectura_ubicacion.dart';
import 'proveedor_ubicacion.dart';

/// Ubicación tomada del GPS del celular del chofer.
///
/// Por ahora funciona con la app abierta. El seguimiento en segundo plano
/// (pantalla apagada) llega en el paso 2.
class ProveedorCelular implements ProveedorUbicacion {
  ProveedorCelular({this.metrosEntreLecturas = 25});

  /// Solo se reporta una nueva posición si el camión se movió esta distancia.
  final int metrosEntreLecturas;

  @override
  FuenteUbicacion get fuente => FuenteUbicacion.celular;

  @override
  Future<String?> prepararse() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'La ubicación del celular está apagada. Prendela para compartirla.';
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    return switch (permiso) {
      LocationPermission.denied => 'Hace falta permiso de ubicación.',
      LocationPermission.deniedForever =>
        'El permiso de ubicación está bloqueado. Activalo en Ajustes.',
      _ => null,
    };
  }

  @override
  Stream<LecturaUbicacion> lecturas() =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: metrosEntreLecturas,
        ),
      ).map(
        (p) => LecturaUbicacion(
          latitud: p.latitude,
          longitud: p.longitude,
          fecha: p.timestamp,
          fuente: fuente,
          // geolocator da m/s; lo pasamos a km/h.
          velocidadKmh: p.speed >= 0 ? p.speed * 3.6 : null,
          rumbo: p.heading >= 0 ? p.heading : null,
          precisionMetros: p.accuracy,
        ),
      );
}
