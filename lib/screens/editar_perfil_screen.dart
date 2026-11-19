import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../models/validadores.dart';
import '../repositories/api_client.dart';
import '../repositories/cuenta_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/cuadro_errores.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';

// Editar los datos personales: nombre, apellido y telefono.
// El correo y el DNI no se cambian porque identifican la cuenta.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  late final _nombreCtrl = TextEditingController(text: UserSession.nombre);
  late final _apellidoCtrl = TextEditingController(text: UserSession.apellido);
  late final _telefonoCtrl =
      TextEditingController(text: _soloDiez(UserSession.telefono));
  List<String> _errores = [];
  bool _guardando = false;

  // "+54 9 1139373911" -> "1139373911"
  static String _soloDiez(String telefono) {
    final d = telefono.replaceAll(RegExp(r'\D'), '');
    return d.length > 10 ? d.substring(d.length - 10) : d;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    final nombre = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    final tel = _telefonoCtrl.text.replaceAll(RegExp(r'\D'), '');

    final errores = <String>[];
    if (nombre.isEmpty) errores.add('Escribe tu nombre');
    if (apellido.isEmpty) errores.add('Escribe tu apellido');
    if (!Validadores.telefono(tel)) {
      errores.add('El teléfono debe tener 10 números (código de área + número, '
          'sin 0 ni 15)');
    }
    if (errores.isNotEmpty) {
      setState(() => _errores = errores);
      return;
    }

    setState(() {
      _errores = [];
      _guardando = true;
    });
    try {
      // Se guarda en la base de datos
      await CuentaRepository.guardarPerfil(
        nombre: nombre,
        apellido: apellido,
        telefono: tel,
      );
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errores = [e.mensaje];
        _guardando = false;
      });
      return;
    }
    if (!mounted) return;

    final telefono = '+54 9 $tel';
    UserSession.nombre = nombre;
    UserSession.apellido = apellido;
    UserSession.telefono = telefono;
    final cuenta = UserSession.cuentaActual;
    if (cuenta != null) {
      cuenta.nombre = nombre;
      cuenta.apellido = apellido;
      cuenta.telefono = telefono;
    }
    final mensajes = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    mensajes.showSnackBar(
      const SnackBar(content: Text('Datos actualizados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OptimaBackButton(),
              Center(child: Text('Editar datos', style: AppText.title)),
              const Divider(color: Colors.black87),
              const SizedBox(height: 12),
              OptimaTextField(
                label: 'Nombre',
                hint: '...',
                controller: _nombreCtrl,
              ),
              const SizedBox(height: 14),
              OptimaTextField(
                label: 'Apellido',
                hint: '...',
                controller: _apellidoCtrl,
              ),
              const SizedBox(height: 14),
              Text('Teléfono', style: AppText.campo),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(
                    width: 90,
                    child: OptimaTextField(hint: '+54 9', readOnly: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OptimaTextField(
                      hint: '...',
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'El correo y el DNI no se pueden cambiar.',
                style: AppText.input.copyWith(
                  color: AppColors.navy,
                  fontSize: 12,
                ),
              ),
              CuadroErrores(errores: _errores),
              const SizedBox(height: 24),
              Center(
                child: OptimaLink(
                  text: _guardando ? 'Guardando...' : 'Guardar',
                  onPressed: _guardar,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}