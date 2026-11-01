import 'dart:math';

/// Letras y números fáciles de dictar por teléfono (sin 0/O, 1/I/L).
const _alfabeto = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

/// Genera el código que el dueño le pasa a sus choferes para que se sumen.
String generarCodigoInvitacion({int largo = 6, Random? azar}) {
  final r = azar ?? Random.secure();
  return List.generate(
    largo,
    (_) => _alfabeto[r.nextInt(_alfabeto.length)],
  ).join();
}

/// Pasa a mayúsculas y quita espacios, por si el chofer lo escribe distinto.
String normalizarCodigo(String codigo) =>
    codigo.toUpperCase().replaceAll(RegExp(r'\s'), '');
