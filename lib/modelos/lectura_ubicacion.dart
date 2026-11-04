/// De dónde viene la ubicación de un camión.
enum FuenteUbicacion {
  /// El celular del chofer (también con la pantalla apagada).
  celular,

  /// Un rastreador GPS 4G instalado en el camión, que reporta a un servidor.
  gps;

  static FuenteUbicacion desdeTexto(String? texto) =>
      FuenteUbicacion.values.firstWhere(
        (f) => f.name == texto,
        orElse: () => FuenteUbicacion.celular,
      );

  String get etiqueta => switch (this) {
    FuenteUbicacion.celular => 'Celular del chofer',
    FuenteUbicacion.gps => 'GPS 4G',
  };
}

/// Una posición del camión en un momento dado.
///
/// Es el mismo formato venga del celular o del GPS 4G, así el dueño ve
/// todo igual en el mapa sin importar la fuente.
class LecturaUbicacion {
  const LecturaUbicacion({
    required this.latitud,
    required this.longitud,
    required this.fecha,
    required this.fuente,
    this.velocidadKmh,
    this.rumbo,
    this.precisionMetros,
  });

  final double latitud;
  final double longitud;
  final DateTime fecha;
  final FuenteUbicacion fuente;
  final double? velocidadKmh;

  /// Grados respecto al norte (0-360).
  final double? rumbo;
  final double? precisionMetros;

  /// La fecha se guarda en milisegundos para que el mismo formato sirva
  /// desde la app y desde un servidor que reciba datos de un GPS.
  Map<String, dynamic> aMapa() => {
    'lat': latitud,
    'lng': longitud,
    'fechaMs': fecha.millisecondsSinceEpoch,
    'fuente': fuente.name,
    if (velocidadKmh != null) 'velocidadKmh': velocidadKmh,
    if (rumbo != null) 'rumbo': rumbo,
    if (precisionMetros != null) 'precisionMetros': precisionMetros,
  };

  factory LecturaUbicacion.desdeMapa(Map<String, dynamic> datos) =>
      LecturaUbicacion(
        latitud: (datos['lat'] as num).toDouble(),
        longitud: (datos['lng'] as num).toDouble(),
        fecha: DateTime.fromMillisecondsSinceEpoch(
          (datos['fechaMs'] as num).toInt(),
        ),
        fuente: FuenteUbicacion.desdeTexto(datos['fuente'] as String?),
        velocidadKmh: (datos['velocidadKmh'] as num?)?.toDouble(),
        rumbo: (datos['rumbo'] as num?)?.toDouble(),
        precisionMetros: (datos['precisionMetros'] as num?)?.toDouble(),
      );
}
