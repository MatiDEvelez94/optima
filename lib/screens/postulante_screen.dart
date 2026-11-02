import 'package:flutter/material.dart';
import '../models/cuenta.dart';
import '../models/whatsapp.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import 'cv_screen.dart';

// Perfil de una persona que mando solicitud (lo ve el dueño del salon).
// Al tocar Confirmar o Rechazar vuelve al inicio avisando que decidio.
class PostulanteScreen extends StatelessWidget {
  const PostulanteScreen({
    super.key,
    required this.nombre,
    required this.profesion,
    this.calificacion, // null = todavia no tiene calificaciones
    this.telefono,
    this.cuenta,
  });

  final String nombre;
  final String profesion;
  final double? calificacion;
  final String? telefono; // el que cargo al registrarse (si no, el de prueba)
  final Cuenta? cuenta; // null = persona de ejemplo

  // Abre WhatsApp directo con el telefono de la persona
  void _contactar(BuildContext context) {
    Whatsapp.abrir(
      context,
      telefono: telefono ?? Whatsapp.telefonoDePrueba,
      mensaje: Whatsapp.mensajeParaPostulante(
        nombre: nombre,
        profesion: profesion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OptimaBackButton(),
                    Center(
                      child: CircleAvatar(
                        radius: 57,
                        backgroundColor: AppColors.navy,
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: AppColors.field,
                          backgroundImage: cuenta?.foto != null
                              ? MemoryImage(cuenta!.foto!)
                              : null,
                          child: cuenta?.foto == null
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
                    _InfoField(label: 'Nombre y apellido', value: nombre),
                    _InfoField(label: 'Profesión', value: profesion),
                    _InfoField(
                      label: 'Calificación',
                      value: calificacion == null
                          ? 'Sin calificaciones'
                          : calificacion!.toStringAsFixed(1),
                      icon: Icons.star,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: OptimaButton(
                        text: 'Ver CV',
                        filled: false,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CvScreen(
                                nombre: nombre,
                                profesion: profesion,
                                telefono: telefono,
                                cuenta: cuenta,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: OptimaButton(
                        text: 'Contactarte',
                        filled: false,
                        onPressed: () => _contactar(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Barra de abajo: decision del dueño
            Container(
              color: AppColors.navyLight,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OptimaButton(
                      text: 'Rechazar',
                      filled: false,
                      width: double.infinity,
                      onPressed: () => Navigator.pop(context, 'rechazada'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OptimaButton(
                      text: 'Confirmar',
                      filled: false,
                      width: double.infinity,
                      onPressed: () => Navigator.pop(context, 'confirmada'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

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
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: AppColors.navy),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    value,
                    style: AppText.input.copyWith(color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
