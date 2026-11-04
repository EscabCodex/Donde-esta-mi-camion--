import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:geolocator/geolocator.dart';

import '../modelos/lectura_ubicacion.dart';
import 'proveedor_ubicacion.dart';

/// Ubicación tomada del GPS del celular del chofer.
///
/// En Android corre como "servicio en primer plano": mientras comparte,
/// queda un aviso fijo en la barra de notificaciones y la ubicación se sigue
/// mandando aunque el chofer apague la pantalla o cambie de app.
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
    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: metrosEntreLecturas,
      intervalDuration: const Duration(seconds: 10),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationTitle: 'Compartiendo ubicación',
        notificationText:
            'El dueño ve dónde está el camión. Podés apagar la pantalla.',
        notificationChannelName: 'Ubicación del camión',
        enableWakeLock: true,
        setOngoing: true,
        color: Color(0xFF1565C0),
      ),
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
