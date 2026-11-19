import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  // Muestra el logo 3 segundos y, mientras tanto, mira si la persona ya tenia
  // la sesion abierta en el servidor (por ejemplo al recargar la pagina)
  Future<void> _iniciar() async {
    final espera = Future<void>.delayed(const Duration(seconds: 3));
    await AuthRepository.restaurarSesion();
    await espera;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Align(
          alignment: const Alignment(0, -0.3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 140,
                color: AppColors.cream,
                colorBlendMode: BlendMode.multiply,
              ),
              const SizedBox(height: 16),
              Text('ÓPTIMA', style: AppText.logo),
              const SizedBox(height: 8),
              Text('Organiza, Crea, Confía', style: AppText.tagline),
            ],
          ),
        ),
      ),
    );
  }
}