import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _correoCtrl = TextEditingController();
  String? _error;
  bool _sent = false;

  void _send() {
    final correo = _correoCtrl.text.trim();
    if (correo.isEmpty || !correo.contains('@')) {
      setState(() => _error = 'Ingresa un correo válido');
      return;
    }
    setState(() {
      _error = null;
      _sent = true;
    });
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OptimaBackButton(),
          Center(
            child: Text(
              'Recuperar Contraseña',
              style: AppText.title.copyWith(fontSize: 28),
            ),
          ),
          const Divider(color: Colors.black87, indent: 20, endIndent: 20),
          const SizedBox(height: 16),
          Text(
            'Ingresa tu correo y te enviaremos los pasos para crear una nueva contraseña.',
            style: AppText.subtitle.copyWith(fontSize: 15, letterSpacing: 0.3),
          ),
          const SizedBox(height: 24),
          OptimaTextField(
            label: 'Correo',
            hint: 'maildeejemplo@gmail.com',
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
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
          Center(child: OptimaLink(text: 'Enviar', onPressed: _send)),
        ],
      ),
    );
  }

  Widget _buildSent() {
    return Column(
      children: [
        const Spacer(flex: 2),
        const Icon(Icons.mail_outline, size: 72, color: AppColors.navy),
        const SizedBox(height: 16),
        Text('Correo enviado', style: AppText.title),
        const Spacer(flex: 1),
        Container(
          width: double.infinity,
          color: AppColors.navyLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
          child: Text(
            'Te enviamos un correo con los pasos para recuperar tu contraseña',
            textAlign: TextAlign.center,
            style: AppText.banner,
          ),
        ),
        const Spacer(flex: 3),
        OptimaLink(
          text: 'Volver al inicio de sesión',
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
        child: _sent ? _buildSent() : _buildForm(),
      ),
    );
  }
}