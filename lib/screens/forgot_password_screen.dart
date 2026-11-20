import 'package:flutter/material.dart';
import '../models/validadores.dart';
import '../repositories/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/cuadro_errores.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';

// Recuperar contraseña en tres pasos:
// 1) correo  2) codigo que llega por mail + nueva contraseña  3) listo
enum _Paso { correo, codigo, listo }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _correoCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _repiteCtrl = TextEditingController();
  _Paso _paso = _Paso.correo;
  List<String> _errores = [];
  String? _info;
  bool _enviando = false;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _codigoCtrl.dispose();
    _nuevaCtrl.dispose();
    _repiteCtrl.dispose();
    super.dispose();
  }

  // Paso 1: el servidor manda el codigo por mail
  Future<void> _pedirCodigo({bool reenvio = false}) async {
    if (_enviando) return;
    final correo = _correoCtrl.text.trim().toLowerCase();
    if (!Validadores.correo(correo)) {
      setState(() => _errores = ['Ingresa un correo válido']);
      return;
    }
    setState(() {
      _errores = [];
      _info = null;
      _enviando = true;
    });
    try {
      await ApiClient.post('/api/recuperar', {'correo': correo});
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errores = [e.mensaje];
        _enviando = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _paso = _Paso.codigo;
      _info = reenvio ? 'Te enviamos un código nuevo' : null;
    });
  }

  // Paso 2: se comprueba el codigo y se guarda la nueva contraseña
  Future<void> _confirmar() async {
    if (_enviando) return;
    final codigo = _codigoCtrl.text.trim();
    final nueva = _nuevaCtrl.text;
    final errores = <String>[];
    if (codigo.length != 6) {
      errores.add('El código tiene 6 números');
    }
    if (!Validadores.password(nueva)) {
      errores.add('La nueva contraseña debe tener al menos 6 caracteres');
    }
    if (nueva != _repiteCtrl.text) {
      errores.add('Las contraseñas no coinciden');
    }
    if (errores.isNotEmpty) {
      setState(() {
        _errores = errores;
        _info = null;
      });
      return;
    }
    setState(() {
      _errores = [];
      _info = null;
      _enviando = true;
    });
    try {
      await ApiClient.post('/api/recuperar/confirmar', {
        'correo': _correoCtrl.text.trim().toLowerCase(),
        'codigo': codigo,
        'nueva': nueva,
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _errores = [e.mensaje];
        _enviando = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _paso = _Paso.listo;
    });
  }

  Widget _buildCorreo() {
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
            'Ingresa tu correo y te enviaremos un código para crear una nueva contraseña.',
            style: AppText.subtitle.copyWith(fontSize: 15, letterSpacing: 0.3),
          ),
          const SizedBox(height: 24),
          OptimaTextField(
            label: 'Correo',
            hint: 'maildeejemplo@gmail.com',
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
          CuadroErrores(errores: _errores),
          const SizedBox(height: 40),
          Center(
            child: OptimaLink(
              text: _enviando ? 'Enviando...' : 'Enviar',
              onPressed: _pedirCodigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodigo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flecha para volver al paso del correo (por si se equivocó de mail)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => setState(() {
                _paso = _Paso.correo;
                _errores = [];
                _info = null;
              }),
              icon: const Icon(Icons.arrow_back, color: AppColors.navy),
            ),
          ),
          Center(
            child: Text(
              'Revisa tu correo',
              style: AppText.title.copyWith(fontSize: 28),
            ),
          ),
          const Divider(color: Colors.black87, indent: 20, endIndent: 20),
          const SizedBox(height: 16),
          Text(
            'Te enviamos un código de 6 números a ${_correoCtrl.text.trim()}. '
            'Vale 15 minutos. Si no lo ves, mirá en spam.',
            style: AppText.subtitle.copyWith(fontSize: 15, letterSpacing: 0.3),
          ),
          const SizedBox(height: 24),
          OptimaTextField(
            label: 'Código',
            hint: '123456',
            controller: _codigoCtrl,
            keyboardType: TextInputType.number,
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
          if (_info != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _info!,
                style: AppText.input.copyWith(color: AppColors.navy),
              ),
            ),
          CuadroErrores(errores: _errores),
          const SizedBox(height: 32),
          Center(
            child: OptimaLink(
              text: _enviando ? 'Guardando...' : 'Confirmar',
              onPressed: _confirmar,
            ),
          ),
          Center(
            child: OptimaLink(
              text: 'Enviar el código de nuevo',
              onPressed: () => _pedirCodigo(reenvio: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListo() {
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
            'Ya puedes iniciar sesión con tu nueva contraseña',
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
    final Widget cuerpo;
    switch (_paso) {
      case _Paso.correo:
        cuerpo = _buildCorreo();
      case _Paso.codigo:
        cuerpo = _buildCodigo();
      case _Paso.listo:
        cuerpo = _buildListo();
    }
    return Scaffold(body: GradientBackground(child: cuerpo));
  }
}