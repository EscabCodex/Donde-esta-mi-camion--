import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../modelos/lectura_ubicacion.dart';
import 'proveedor_ubicacion.dart';

/// Ubicación tomada del GPS del celular del chofer.
///
/// En Android se usa desde [ServicioUbicacion], que la sigue leyendo aunque
/// la app esté cerrada.
class ProveedorCelular implements ProveedorUbicacion {
  ProveedorCelular({this.metrosEntreLecturas = 25});

  /// Solo se reporta una nueva posición si el camión se movió esta distancia.
  final int metrosEntreLecturas;

  static bool get _esAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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

  /// true si el chofer eligió "Permitir todo el tiempo".
  Future<bool> tienePermisoSiempre() async =>
      await Geolocator.checkPermission() == LocationPermission.always;

  /// Pide pasar de "solo mientras se usa la app" a "todo el tiempo".
  ///
  /// En Android 11 o más nuevo esto abre la pantalla de permisos de la app,
  /// donde el chofer tiene que tocar "Permitir todo el tiempo".
  Future<bool> pedirPermisoSiempre() async {
    if (!_esAndroid) return true;
    if (await tienePermisoSiempre()) return true;
    final permiso = await Geolocator.requestPermission();
    return permiso == LocationPermission.always;
  }

  LocationSettings _ajustes() {
    if (!_esAndroid) {
      return LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: metrosEntreLecturas,
      );
    }
    // El aviso fijo lo pone ServicioUbicacion, no geolocator.
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: metrosEntreLecturas,
      intervalDuration: const Duration(seconds: 10),
    );
  }

  @override
  Stream<LecturaUbicacion> lecturas() =>
      Geolocator.getPositionStream(locationSettings: _ajustes()).map(
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
