/// Rol de cada persona dentro de una flota.
enum Rol {
  dueno,
  chofer;

  static Rol desdeTexto(String? texto) =>
      Rol.values.firstWhere((r) => r.name == texto, orElse: () => Rol.chofer);
}

/// Perfil guardado en `usuarios/{uid}`.
class Usuario {
  const Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.flotaId,
  });

  final String uid;
  final String nombre;
  final String email;
  final Rol rol;

  /// Flota a la que pertenece. Para el dueño es igual a su uid.
  final String flotaId;

  bool get esDueno => rol == Rol.dueno;

  factory Usuario.desdeMapa(String uid, Map<String, dynamic> datos) => Usuario(
    uid: uid,
    nombre: datos['nombre'] as String? ?? '',
    email: datos['email'] as String? ?? '',
    rol: Rol.desdeTexto(datos['rol'] as String?),
    flotaId: datos['flotaId'] as String? ?? '',
  );

  Map<String, dynamic> aMapa() => {
    'nombre': nombre,
    'email': email,
    'rol': rol.name,
    'flotaId': flotaId,
  };
}
