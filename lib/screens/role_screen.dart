import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/role_card.dart';
import 'register_screen.dart';
import 'salon_owner_screen.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const OptimaBackButton(),
              Text('Rol', style: AppText.title),
              const Divider(color: Colors.black87, indent: 20, endIndent: 20),
              const SizedBox(height: 8),
              Text('Elige según tu objetivo', style: AppText.subtitle),
              const SizedBox(height: 24),
              RoleCard(
                image: 'assets/images/salon.jpg',
                text: 'Quiero inscribir mi salón',
                onNext: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalonOwnerScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              RoleCard(
                image: 'assets/images/trabajo.jpg',
                text: 'Quiero buscar trabajo',
                onNext: () {
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