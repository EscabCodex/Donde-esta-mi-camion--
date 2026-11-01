import 'package:flutter/material.dart';

import '../../servicios/auth_servicio.dart';
import '../../widgets/formulario_auth.dart';
import 'registro.dart';

class InicioSesion extends StatefulWidget {
  const InicioSesion({super.key, required this.auth});

  final AuthServicio auth;

  @override
  State<InicioSesion> createState() => _InicioSesionState();
}

class _InicioSesionState extends State<InicioSesion> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _clave = TextEditingController();
  bool _ocupado = false;

  @override
  void dispose() {
    _email.dispose();
    _clave.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _ocupado = true);
    await ejecutarConAviso(
      context,
      () => widget.auth.iniciarSesion(_email.text, _clave.text),
      mensajeDeError,
    );
    if (mounted) setState(() => _ocupado = false);
  }

  void _irARegistro(bool esDueno) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Registro(auth: widget.auth, esDueno: esDueno),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: MarcoAuth(
        titulo: 'Ingresar',
        hijos: [
          const Icon(Icons.local_shipping, size: 72),
          Text(
            'Dónde está mi camión',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
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
            validator: requerido,
            onFieldSubmitted: (_) => _entrar(),
          ),
          FilledButton(
            onPressed: _ocupado ? null : _entrar,
            child: Text(_ocupado ? 'Ingresando…' : 'Ingresar'),
          ),
          const Divider(height: 32),
          OutlinedButton(
            onPressed: () => _irARegistro(false),
            child: const Text('Soy chofer y tengo un código'),
          ),
          TextButton(
            onPressed: () => _irARegistro(true),
            child: const Text('Soy dueño, crear mi flota'),
          ),
        ],
      ),
    );
  }
}
