import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
  final _correoCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _repeatCtrl = TextEditingController();
  String? _error;
  bool _done = false;

  void _confirm() {
    final correo = _correoCtrl.text.trim();
    final nueva = _newCtrl.text;
    final repite = _repeatCtrl.text;

    String? error;
    if (correo.isEmpty || nueva.isEmpty || repite.isEmpty) {
      error = 'Completa todos los campos';
    } else if (!correo.contains('@')) {
      error = 'Ingresa un correo valido';
    } else if (nueva.length < 6) {
      error = 'La contraseña debe tener al menos 6 caracteres';
    } else if (nueva != repite) {
      error = 'Las contraseñas no coinciden';
    }

    setState(() {
      _error = error;
      _done = error == null;
    });
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _newCtrl.dispose();
    _repeatCtrl.dispose();
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
            label: 'Correo',
            hint: 'maildeejemplo@gmail.com',
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          OptimaTextField(
            label: 'Nueva contraseña',
            hint: '...',
            controller: _newCtrl,
            obscure: true,
          ),
          const SizedBox(height: 20),
          OptimaTextField(
            label: 'Repite la contraseña',
            hint: '...',
            controller: _repeatCtrl,
            obscure: true,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: AppText.input.copyWith(color: Colors.red.shade800),
              ),
            ),
          const SizedBox(height: 40),
          Center(child: OptimaLink(text: 'Confirmar', onPressed: _confirm)),
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