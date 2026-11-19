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

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _repiteCtrl = TextEditingController();
  List<String> _errores = [];
  bool _done = false;
  bool _enviando = false;

  // Revisa los datos y, si estan bien, cambia la contraseña de la cuenta
  Future<void> _confirm() async {
    if (_enviando) return;
    final actual = _actualCtrl.text;
    final nueva = _nuevaCtrl.text;
    final repite = _repiteCtrl.text;
    final errores = <String>[];

    if (actual.isEmpty) {
      errores.add('Escribe tu contraseña actual');
    }
    if (!Validadores.password(nueva)) {
      errores.add('La nueva contraseña debe tener al menos 6 caracteres');
    } else if (nueva == actual) {
      errores.add('La nueva contraseña tiene que ser distinta de la actual');
    }
    if (nueva != repite) {
      errores.add('Las contraseñas nuevas no coinciden');
    }

    if (errores.isNotEmpty) {
      setState(() => _errores = errores);
      return;
    }

    setState(() {
      _errores = [];
      _enviando = true;
    });
    try {
      // El servidor comprueba la contraseña actual y guarda la nueva
      await CuentaRepository.cambiarPassword(actual, nueva);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errores = [e.mensaje];
        _enviando = false;
      });
      return;
    }
    if (!mounted) return;

    final cuenta = UserSession.cuentaActual;
    if (cuenta != null) {
      cuenta.cambiarPassword(nueva);
    } else {
      UserSession.password = nueva;
    }
    setState(() {
      _errores = [];
      _enviando = false;
      _done = true;
    });
  }

  @override
  void dispose() {
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _repiteCtrl.dispose();
    super.dispose();
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OptimaBackButton(),
          Center(child: Text('Cambiar contraseña', style: AppText.title)),
          const Divider(color: Colors.black87, indent: 20, endIndent: 20),
          const SizedBox(height: 24),
          OptimaTextField(
            label: 'Contraseña actual',
            hint: '...',
            controller: _actualCtrl,
            obscure: true,
          ),
          const SizedBox(height: 20),
          OptimaTextField(
            label: 'Nueva contraseña',
            hint: 'mínimo 6 caracteres',
            controller: _nuevaCtrl,
            obscure: true,
          ),
          const SizedBox(height: 20),
          OptimaTextField(
            label: 'Repite la nueva contraseña',
            hint: '...',
            controller: _repiteCtrl,
            obscure: true,
          ),
          CuadroErrores(errores: _errores),
          const SizedBox(height: 40),
          Center(
            child: OptimaLink(
              text: _enviando ? 'Guardando...' : 'Confirmar',
              onPressed: _confirm,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Spacer(flex: 2),
        const Icon(
          Icons.check_circle_outline,
          size: 72,
          color: AppColors.navy,
        ),
        const SizedBox(height: 16),
        Text('Contraseña actualizada', style: AppText.title),
        const Spacer(flex: 1),
        Container(
          width: double.infinity,
          color: AppColors.navyLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
          child: Text(
            'Cambiaste tu contraseña correctamente',
            textAlign: TextAlign.center,
            style: AppText.banner,
          ),
        ),
        const Spacer(flex: 3),
        OptimaLink(
          text: 'Volver al perfil',
          onPressed: () => Navigator.pop(context),
        ),
        const Spacer(flex: 3),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: _done ? _buildSuccess() : _buildForm(),
      ),
    );
  }
}