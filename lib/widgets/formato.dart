import '../modelos/lectura_ubicacion.dart';

/// "hace 3 min", "hace 2 h", etc.
String haceCuanto(DateTime fecha, {DateTime? ahora}) {
  final d = (ahora ?? DateTime.now()).difference(fecha);
  if (d.inSeconds < 60) return 'recién';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  return 'hace ${d.inDays} d';
}

String resumenUbicacion(LecturaUbicacion? l, {DateTime? ahora}) {
  if (l == null) return 'Sin ubicación todavía';
  final vel = l.velocidadKmh == null
      ? ''
      : ' · ${l.velocidadKmh!.round()} km/h';
  return '${l.latitud.toStringAsFixed(5)}, ${l.longitud.toStringAsFixed(5)}'
      '$vel · ${haceCuanto(l.fecha, ahora: ahora)}';
}
