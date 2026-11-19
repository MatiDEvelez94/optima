import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_session.dart';
import '../models/validadores.dart';
import '../repositories/api_client.dart';
import '../repositories/cuenta_repository.dart';
import '../theme/app_text_styles.dart';
import '../widgets/cuadro_errores.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';
import 'salon_data_screen.dart';

// Primer paso para inscribir un salon: datos de la persona duena del salon
class SalonOwnerScreen extends StatefulWidget {
  const SalonOwnerScreen({super.key});

  @override
  State<SalonOwnerScreen> createState() => _SalonOwnerScreenState();
}

class _SalonOwnerScreenState extends State<SalonOwnerScreen> {
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  List<String> _errores = [];
  bool _comprobando = false;

  // Revisa los datos; si algo falla, muestra que hay que corregir
  Future<void> _continue() async {
    if (_comprobando) return;
    final correo = _correoCtrl.text.trim().toLowerCase();
    final errores = <String>[];

    if (_nombreCtrl.text.trim().isEmpty) errores.add('Escribe tu nombre');
    if (_apellidoCtrl.text.trim().isEmpty) errores.add('Escribe tu apellido');
    if (!Validadores.correo(correo)) {
      errores.add('Escribe un correo válido, por ejemplo nombre@gmail.com');
    } else if (correo == UserSession.adminCorreo) {
      errores.add('Ya existe una cuenta con ese correo');
    } else {
      // Se consulta en la base de datos si el correo ya esta registrado
      setState(() => _comprobando = true);
      try {
        if (await CuentaRepository.correoExiste(correo)) {
          errores.add('Ya existe una cuenta con ese correo');
        }
      } on ApiError catch (e) {
        errores.add(e.mensaje);
      }
      if (!mounted) return;
      setState(() => _comprobando = false);
    }
    if (!Validadores.password(_passCtrl.text)) {
      errores.add('La contraseña debe tener al menos 6 caracteres');
    }
    if (!Validadores.telefono(_telefonoCtrl.text.trim())) {
      errores.add(
        'El teléfono debe tener 10 números: código de área y número, '
        'sin 0 ni 15',
      );
    }
    if (!Validadores.dni(_dniCtrl.text)) {
      errores.add('El DNI debe tener 7 u 8 números');
    }

    if (errores.isNotEmpty) {
      setState(() => _errores = errores);
      return;
    }

    UserSession.nombre = _nombreCtrl.text.trim();
    UserSession.apellido = _apellidoCtrl.text.trim();
    UserSession.correo = correo;
    UserSession.password = _passCtrl.text;
    UserSession.telefono = '+54 9 ${_telefonoCtrl.text.trim()}';
    UserSession.dni = _dniCtrl.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SalonDataScreen()),
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _telefonoCtrl.dispose();
    _dniCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OptimaBackButton(),
              Center(child: Text('Datos del Dueño', style: AppText.title)),
              const Divider(color: Colors.black87),
              const SizedBox(height: 16),
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
              OptimaTextField(
                label: 'Correo electrónico',
                hint: 'maildeejemplo@gmail.com',
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              OptimaTextField(
                label: 'Contraseña',
                hint: 'mínimo 6 caracteres',
                controller: _passCtrl,
                obscure: true,
              ),
              const SizedBox(height: 14),

              Text('Teléfono', style: AppText.campo),
              const SizedBox(height: 6),
              Row(
                children: [
                  Image.asset('assets/icons/ar.png', width: 32),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 90,
                    child: OptimaTextField(hint: '+54 9', readOnly: true),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: AppText.input.copyWith(color: Colors.black87),
                      decoration: optimaDecoration('2611234567'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text('DNI', style: AppText.campo),
              const SizedBox(height: 6),
              TextField(
                controller: _dniCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                style: AppText.input.copyWith(color: Colors.black87),
                decoration: optimaDecoration('...'),
              ),

              CuadroErrores(errores: _errores),

              const SizedBox(height: 40),
              Center(
                child: OptimaLink(
                  text: _comprobando ? 'Comprobando...' : 'Continuar',
                  onPressed: _continue,
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