import 'package:flutter/material.dart';
import '../models/cuenta.dart';
import '../models/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'role_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _iniciarSesion() {
    final correo = _correoCtrl.text.trim().toLowerCase();
    final pass = _passCtrl.text;

    if (correo == UserSession.adminCorreo) {
      // Cuenta del administrador
      if (pass != UserSession.adminPass) {
        setState(() => _error = 'Correo o contraseña incorrectos');
        return;
      }
      UserSession.rol = 'admin';
      UserSession.correo = UserSession.adminCorreo;
      UserSession.logueado = true;
    } else {
      // Cuentas registradas en la app
      final cuenta = Cuenta.buscar(correo);
      if (cuenta == null) {
        setState(() => _error = 'No existe una cuenta con ese correo');
        return;
      }
      if (cuenta.password != pass) {
        setState(() => _error = 'Correo o contraseña incorrectos');
        return;
      }
      cuenta.iniciarSesion();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            children: [
              const OptimaBackButton(),
              Image.asset(
                'assets/images/logo.png',
                height: 100,
                color: AppColors.cream,
                colorBlendMode: BlendMode.multiply,
              ),
              const SizedBox(height: 12),
              Text('ÓPTIMA', style: AppText.logo),
              Text('Organiza, Crea, Confía', style: AppText.tagline),
              const SizedBox(height: 16),
              const Divider(color: Colors.black87),
              const SizedBox(height: 32),
              OptimaTextField(
                hint: 'correo electrónico',
                controller: _correoCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              OptimaTextField(
                hint: 'contraseña',
                controller: _passCtrl,
                obscure: true,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppText.input.copyWith(color: Colors.red.shade800),
                  ),
                ),
              const SizedBox(height: 20),
              OptimaButton(text: 'Iniciar sesión', onPressed: _iniciarSesion),
              const SizedBox(height: 8),
              OptimaLink(
                text: 'Recuperar Contraseña',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 50),
              const Text(
                'O',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 60),
              OptimaButton(
                text: 'Crea una cuenta',
                filled: false,
                width: double.infinity,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoleScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
