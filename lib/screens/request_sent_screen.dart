import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_button.dart';
import 'home_screen.dart';

class RequestSentScreen extends StatelessWidget {
  const RequestSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text('Solicitud Enviada', style: AppText.title),
            const Spacer(flex: 2),
            Container(
              width: double.infinity,
              color: AppColors.navyLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 28),
              child: Text(
                'Este proceso puede demorar de 24 a 48h, sera notificado via mail cuando se apruebe',
                textAlign: TextAlign.center,
                style: AppText.banner,
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: OptimaLink(
                text: 'Acceder al inicio',
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}