import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/carrusel_fotos.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';

// Datos completos del salon inscripto
class SalonDetailScreen extends StatelessWidget {
  const SalonDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nombre =
        UserSession.salonNombre.isEmpty ? '-' : UserSession.salonNombre;
    final direccion =
        UserSession.salonDireccion.isEmpty ? '-' : UserSession.salonDireccion;
    final capacidad = UserSession.salonCapacidad.isEmpty
        ? '-'
        : '${UserSession.salonCapacidad} personas';

    // Todas las fotos del salon van arriba, en el carrusel
    final List<ImageProvider> fotos = UserSession.salonFotos.isNotEmpty
        ? UserSession.salonFotos
            .map<ImageProvider>((f) => MemoryImage(f))
            .toList()
        : [const AssetImage('assets/images/salon.jpg')];

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OptimaBackButton(),
              Center(child: Text('Tu salón', style: AppText.title)),
              const Divider(color: Colors.black87, indent: 20, endIndent: 20),
              const SizedBox(height: 20),
              CarruselFotos(fotos: fotos),
              const SizedBox(height: 24),
              _DetailRow(label: 'Nombre del salón', value: nombre),
              _DetailRow(label: 'Dirección', value: direccion),
              _DetailRow(label: 'Capacidad', value: capacidad),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
              value,
              style: AppText.input.copyWith(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
