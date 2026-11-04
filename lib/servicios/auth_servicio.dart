import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../modelos/usuario.dart';
import '../ubicacion/servicio_ubicacion.dart';
import 'codigo_invitacion.dart';

/// Inicio de sesión, registro y perfil (con su rol) de cada persona.
class AuthServicio {
  AuthServicio({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = db ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> get cambiosDeSesion => _auth.authStateChanges();

  Stream<Usuario?> perfil(String uid) => _db
      .collection('usuarios')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? Usuario.desdeMapa(d.id, d.data()!) : null);

  Future<void> iniciarSesion(String email, String clave) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: clave);

  /// Al cerrar sesión también se deja de compartir la ubicación.
  Future<void> cerrarSesion() async {
    await ServicioUbicacion.detener();
    await _auth.signOut();
  }

  /// Crea la cuenta del dueño junto con su flota y su código de invitación.
  Future<void> registrarDueno({
    required String nombre,
    required String email,
    required String clave,
    required String nombreFlota,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: clave,
    );
    final uid = cred.user!.uid;
    final codigo = generarCodigoInvitacion();
    final lote = _db.batch()
      ..set(_db.collection('flotas').doc(uid), {
        'nombre': nombreFlota.trim(),
        'duenoUid': uid,
        'codigoInvitacion': codigo,
        'creada': FieldValue.serverTimestamp(),
      })
      ..set(_db.collection('invitaciones').doc(codigo), {'flotaId': uid})
      ..set(
        _db.collection('usuarios').doc(uid),
        Usuario(
          uid: uid,
          nombre: nombre.trim(),
          email: email.trim(),
          rol: Rol.dueno,
          flotaId: uid,
        ).aMapa(),
      );
    await lote.commit();
  }

  /// Crea la cuenta de un chofer y lo suma a la flota del código.
  Future<void> registrarChofer({
    required String nombre,
    required String email,
    required String clave,
    required String codigoInvitacion,
  }) async {
    final codigo = normalizarCodigo(codigoInvitacion);
    if (codigo.isEmpty) throw const CodigoInvalido();
    final invitacion = await _db.collection('invitaciones').doc(codigo).get();
    final flotaId = invitacion.data()?['flotaId'] as String?;
    if (flotaId == null) throw const CodigoInvalido();

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: clave,
    );
    final uid = cred.user!.uid;
    await _db.collection('usuarios').doc(uid).set({
      ...Usuario(
        uid: uid,
        nombre: nombre.trim(),
        email: email.trim(),
        rol: Rol.chofer,
        flotaId: flotaId,
      ).aMapa(),
      // Las reglas de Firestore lo usan para verificar la invitación.
      'codigoInvitacion': codigo,
    });
  }
}

class CodigoInvalido implements Exception {
  const CodigoInvalido();

  @override
  String toString() => 'El código de invitación no existe.';
}

/// Traduce los errores de Firebase a mensajes para la persona.
String mensajeDeError(Object error) {
  if (error is CodigoInvalido) return error.toString();
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => 'El email no es válido.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email o contraseña incorrectos.',
      'email-already-in-use' => 'Ya existe una cuenta con ese email.',
      'weak-password' => 'La contraseña tiene que tener al menos 6 caracteres.',
      'network-request-failed' => 'Sin conexión a internet.',
      'too-many-requests' => 'Demasiados intentos. Probá en unos minutos.',
      _ => 'No se pudo completar (${error.code}).',
    };
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'No tenés permiso para hacer esto.';
  }
  return 'Ocurrió un error inesperado.';
}
