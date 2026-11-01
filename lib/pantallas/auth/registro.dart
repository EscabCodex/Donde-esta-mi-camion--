import 'package:flutter/material.dart';

import '../../servicios/auth_servicio.dart';
import '../../widgets/formulario_auth.dart';

/// Registro de dueño (crea una flota) o de chofer (se suma con un código).
class Registro extends StatefulWidget {
  const Registro({super.key, required this.auth, required this.esDueno});

  final AuthServicio auth;
  final bool esDueno;

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _clave = TextEditingController();
  final _extra = TextEditingController(); // nombre de flota o código
  bool _ocupado = false;

  @override
  void dispose() {
    for (final c in [_nombre, _email, _clave, _extra]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _ocupado = true);
    final ok = await ejecutarConAviso(
      context,
      () => widget.esDueno
          ? widget.auth.registrarDueno(
              nombre: _nombre.text,
              email: _email.text,
              clave: _clave.text,
              nombreFlota: _extra.text,
            )
          : widget.auth.registrarChofer(
              nombre: _nombre.text,
              email: _email.text,
              clave: _clave.text,
              codigoInvitacion: _extra.text,
            ),
      mensajeDeError,
    );
    if (!mounted) return;
    if (ok) {
      // La compuerta ya muestra la pantalla del rol; volvemos a la raíz.
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dueno = widget.esDueno;
    return Form(
      key: _form,
      child: MarcoAuth(
        titulo: dueno ? 'Crear mi flota' : 'Sumarme como chofer',
        hijos: [
          Text(
            dueno
                ? 'Creá tu cuenta de dueño. Después vas a tener un código '
                      'para que se sumen tus choferes.'
                : 'Pedile el código de invitación al dueño de la flota.',
          ),
          TextFormField(
            controller: _nombre,
            decoration: const InputDecoration(labelText: 'Tu nombre'),
            textCapitalization: TextCapitalization.words,
            validator: requerido,
          ),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: validarEmail,
          ),
          TextFormField(
            controller: _clave,
            decoration: const InputDecoration(labelText: 'Contraseña'),
            obscureText: true,
            validator: validarClave,
          ),
          TextFormField(
            controller: _extra,
            decoration: InputDecoration(
              labelText: dueno ? 'Nombre de la flota' : 'Código de invitación',
            ),
            textCapitalization: dueno
                ? TextCapitalization.words
                : TextCapitalization.characters,
            validator: requerido,
          ),
          FilledButton(
            onPressed: _ocupado ? null : _registrar,
            child: Text(_ocupado ? 'Creando cuenta…' : 'Crear cuenta'),
          ),
        ],
      ),
    );
  }
}
