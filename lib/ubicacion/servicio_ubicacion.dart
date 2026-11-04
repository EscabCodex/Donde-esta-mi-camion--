import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'proveedor_celular.dart';
import 'publicador_ubicacion.dart';

/// Comparte la ubicación desde un servicio de Android aparte de la pantalla.
///
/// Así sigue mandando aunque el chofer apague la pantalla, cierre la app
/// deslizándola o reinicie el celular. Solo se corta cuando toca "Dejar de
/// compartir" o cierra sesión.
///
/// Qué camión comparte se guarda en el celular, para que el servicio sepa
/// qué hacer cuando Android lo vuelve a arrancar solo.
class ServicioUbicacion {
  ServicioUbicacion._();

  static const _claveFlota = 'compartiendo.flotaId';
  static const _claveCamion = 'compartiendo.camionId';
  static const _ordenDetener = 'detener';
  static const _avisoError = 'error';

  /// Solo en Android hay servicio aparte. En la web se comparte con la
  /// página abierta.
  static bool get disponible =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static final _servicio = FlutterBackgroundService();

  /// Se llama una vez al abrir la app.
  static Future<void> configurar() async {
    if (!disponible) return;
    await _servicio.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: alArrancarServicio,
        autoStart: false,
        // Si el celular se reinicia mientras compartía, vuelve a arrancar.
        // Si no estaba compartiendo, el servicio se apaga solo enseguida.
        autoStartOnBoot: true,
        isForegroundMode: true,
        initialNotificationTitle: 'Compartiendo ubicación',
        initialNotificationContent:
            'El dueño ve dónde está el camión. Podés apagar la pantalla.',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(autoStart: false),
    );
  }

  /// El camión que este celular está compartiendo, o null.
  static Future<String?> camionCompartido() async {
    if (!disponible) return null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final camion = prefs.getString(_claveCamion);
    if (camion == null) return null;
    return await _servicio.isRunning() ? camion : null;
  }

  static Future<void> iniciar({
    required String flotaId,
    required String camionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveFlota, flotaId);
    await prefs.setString(_claveCamion, camionId);
    if (await _servicio.isRunning()) {
      // Ya corría con otro camión: lo reiniciamos con el nuevo.
      _servicio.invoke(_ordenDetener);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    await _servicio.startService();
  }

  static Future<void> detener() async {
    if (!disponible) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveFlota);
    await prefs.remove(_claveCamion);
    if (await _servicio.isRunning()) _servicio.invoke(_ordenDetener);
  }

  /// Errores que el servicio no puede mostrar porque no tiene pantalla.
  static Stream<String> errores() => _servicio
      .on(_avisoError)
      .map((d) => d?['mensaje'] as String? ?? 'Error al compartir.');
}

/// Lo que corre dentro del servicio, sin pantalla.
@pragma('vm:entry-point')
Future<void> alArrancarServicio(ServiceInstance servicio) async {
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final flotaId = prefs.getString(ServicioUbicacion._claveFlota);
  final camionId = prefs.getString(ServicioUbicacion._claveCamion);
  if (flotaId == null || camionId == null) {
    // Arrancó solo (por ejemplo al prender el celular) sin estar compartiendo.
    await servicio.stopSelf();
    return;
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  StreamSubscription<Object?>? ubicacion;
  StreamSubscription<User?>? sesion;
  var terminado = false;
  Future<void> terminar() async {
    if (terminado) return;
    terminado = true;
    await ubicacion?.cancel();
    await sesion?.cancel();
    await servicio.stopSelf();
  }

  servicio.on(ServicioUbicacion._ordenDetener).listen((_) => terminar());

  // Si se cierra la sesión, se deja de compartir.
  sesion = FirebaseAuth.instance.authStateChanges().listen((usuario) async {
    if (usuario == null) {
      await prefs.remove(ServicioUbicacion._claveFlota);
      await prefs.remove(ServicioUbicacion._claveCamion);
      await terminar();
    }
  });

  final publicador = PublicadorUbicacion(flotaId: flotaId, camionId: camionId);
  ubicacion = ProveedorCelular().lecturas().listen(
    (lectura) async {
      try {
        await publicador.publicar(lectura);
        if (servicio is AndroidServiceInstance) {
          final h = lectura.fecha.toLocal();
          final hora =
              '${h.hour.toString().padLeft(2, '0')}:'
              '${h.minute.toString().padLeft(2, '0')}';
          await servicio.setForegroundNotificationInfo(
            title: 'Compartiendo ubicación',
            content: 'Último envío: $hora. Podés apagar la pantalla.',
          );
        }
      } catch (e) {
        servicio.invoke(ServicioUbicacion._avisoError, {'mensaje': '$e'});
      }
    },
    onError: (Object e) =>
        servicio.invoke(ServicioUbicacion._avisoError, {'mensaje': '$e'}),
  );
}
