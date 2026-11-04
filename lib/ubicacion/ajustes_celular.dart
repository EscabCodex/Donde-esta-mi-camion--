import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Ajustes del celular que ayudan a que la ubicación no se corte.
class AjustesCelular {
  static bool get _esAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Android 13 o más nuevo pide permiso para mostrar el aviso fijo
  /// "Compartiendo ubicación". Sin él la ubicación igual se manda, pero el
  /// chofer no ve el aviso.
  static Future<void> pedirNotificaciones() async {
    if (!_esAndroid) return;
    await Permission.notification.request();
  }

  /// true si Android ya no "ahorra batería" con esta app.
  static Future<bool> sinAhorroDeBateria() async {
    if (!_esAndroid) return true;
    return Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Pide que Android no frene la app para ahorrar batería (algunas marcas,
  /// como Xiaomi o Samsung, cortan la ubicación si no).
  static Future<void> pedirSinAhorroDeBateria() async {
    if (!_esAndroid) return;
    await Permission.ignoreBatteryOptimizations.request();
  }
}
