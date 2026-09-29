import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_button.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.navyLight,
        foregroundColor: AppColors.cream,
        centerTitle: true,
        title: Text(
          'Perfil',
          style: AppText.title.copyWith(fontSize: 24, color: AppColors.cream),
        ),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 57,
                  backgroundColor: AppColors.navy,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.field,
                    backgroundImage: UserSession.foto != null
                        ? MemoryImage(UserSession.foto!)
                        : null,
                    child: UserSession.foto == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.hint,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _InfoField(label: 'Nombre', value: UserSession.nombre),
              _InfoField(label: 'Apellido', value: UserSession.apellido),
              _InfoField(
                label: 'Correo electronico',
                value: UserSession.correo,
              ),
              _InfoField(label: 'Telefono', value: UserSession.telefono),
              _InfoField(label: 'DNI', value: UserSession.dni),
              const SizedBox(height: 16),
              Center(
                child: OptimaButton(
                  text: 'Cambiar contraseña',
                  filled: false,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.navy),
            ),
            child: Text(
              value.isEmpty ? '-' : value,
              style: AppText.input.copyWith(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}