import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            children: [
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
              const OptimaTextField(
                hint: 'correo electronico, telefono',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              const OptimaTextField(hint: 'contraseña', obscure: true),
              const SizedBox(height: 20),
              OptimaButton(
                text: 'Iniciar sesion',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
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
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
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