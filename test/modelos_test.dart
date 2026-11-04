import 'dart:math';

import 'package:donde_esta_mi_camion/modelos/camion.dart';
import 'package:donde_esta_mi_camion/modelos/lectura_ubicacion.dart';
import 'package:donde_esta_mi_camion/modelos/usuario.dart';
import 'package:donde_esta_mi_camion/servicios/codigo_invitacion.dart';
import 'package:donde_esta_mi_camion/widgets/formato.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LecturaUbicacion', () {
    test('ida y vuelta por mapa conserva los datos', () {
      final l = LecturaUbicacion(
        latitud: -34.6037,
        longitud: -58.3816,
        fecha: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        fuente: FuenteUbicacion.gps,
        velocidadKmh: 62.5,
        rumbo: 180,
        precisionMetros: 8,
      );
      final copia = LecturaUbicacion.desdeMapa(l.aMapa());
      expect(copia.latitud, l.latitud);
      expect(copia.longitud, l.longitud);
      expect(copia.fecha, l.fecha);
      expect(copia.fuente, FuenteUbicacion.gps);
      expect(copia.velocidadKmh, 62.5);
      expect(copia.rumbo, 180);
      expect(copia.precisionMetros, 8);
    });

    test('acepta enteros y campos opcionales ausentes (ej. desde un GPS)', () {
      final l = LecturaUbicacion.desdeMapa({
        'lat': -34,
        'lng': -58,
        'fechaMs': 1700000000000,
        'fuente': 'gps',
      });
      expect(l.latitud, -34.0);
      expect(l.velocidadKmh, isNull);
    });
  });

  test('Camion lee su última ubicación', () {
    final c = Camion.desdeMapa('abc', {
      'patente': 'AB123CD',
      'fuente': 'celular',
      'choferUid': 'chofer1',
      'ultimaUbicacion': {
        'lat': 1.0,
        'lng': 2.0,
        'fechaMs': 0,
        'fuente': 'celular',
      },
    });
    expect(c.patente, 'AB123CD');
    expect(c.fuente, FuenteUbicacion.celular);
    expect(c.ultimaUbicacion?.longitud, 2.0);
  });

  test('Usuario con rol desconocido queda como chofer', () {
    final u = Usuario.desdeMapa('x', {'rol': 'admin', 'flotaId': 'f'});
    expect(u.rol, Rol.chofer);
    expect(Usuario.desdeMapa('x', {'rol': 'dueno'}).esDueno, isTrue);
  });

  group('código de invitación', () {
    test('tiene 6 caracteres sin letras confusas', () {
      final codigo = generarCodigoInvitacion(azar: Random(1));
      expect(codigo, hasLength(6));
      expect(codigo, matches(RegExp(r'^[A-HJKMNP-Z2-9]{6}$')));
    });

    test('se normaliza lo que escribe el chofer', () {
      expect(normalizarCodigo(' ab3 k7q '), 'AB3K7Q');
    });
  });

  test('haceCuanto', () {
    final ahora = DateTime(2026, 1, 1, 12);
    expect(
      haceCuanto(ahora.subtract(const Duration(seconds: 10)), ahora: ahora),
      'recién',
    );
    expect(
      haceCuanto(ahora.subtract(const Duration(minutes: 5)), ahora: ahora),
      'hace 5 min',
    );
    expect(
      haceCuanto(ahora.subtract(const Duration(hours: 3)), ahora: ahora),
      'hace 3 h',
    );
  });
}
