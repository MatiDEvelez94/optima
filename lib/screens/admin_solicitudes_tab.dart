import 'package:flutter/material.dart';
import '../models/solicitud_salon.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/salon_admin_card.dart';
import 'solicitud_salon_detail_screen.dart';

// Inicio del administrador: solicitudes de salones para verificar
class AdminSolicitudesTab extends StatelessWidget {
  const AdminSolicitudesTab({super.key});

  Future<void> _abrir(BuildContext context, SolicitudSalon s) async {
    final resultado = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => SolicitudSalonDetailScreen(solicitud: s),
      ),
    );
    if (resultado == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${s.salonNombre} $resultado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: ValueListenableBuilder<int>(
          valueListenable: SolicitudSalon.cambios,
          builder: (context, _, __) {
            final pendientes = SolicitudSalon.pendientes;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Solicitudes recibidas',
                      style: AppText.title.copyWith(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '${pendientes.length} pendientes de verificación',
                      style: AppText.input.copyWith(color: AppColors.navy),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pendientes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'No hay solicitudes\npendientes',
                          textAlign: TextAlign.center,
                          style: AppText.subtitle.copyWith(letterSpacing: 0.3),
                        ),
                      ),
                    )
                  else
                    for (final s in pendientes)
                      SalonAdminCard(
                        solicitud: s,
                        onTap: () => _abrir(context, s),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
