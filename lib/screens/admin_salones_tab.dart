import 'package:flutter/material.dart';
import '../models/solicitud_salon.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/salon_admin_card.dart';
import 'solicitud_salon_detail_screen.dart';

// Lupa del administrador: salones aprobados que estan activos
class AdminSalonesTab extends StatelessWidget {
  const AdminSalonesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: ValueListenableBuilder<int>(
          valueListenable: SolicitudSalon.cambios,
          builder: (context, _, __) {
            final activos = SolicitudSalon.activos;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Salones activos',
                      style: AppText.title.copyWith(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '${activos.length} salones aprobados',
                      style: AppText.input.copyWith(color: AppColors.navy),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (activos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'Todavía no hay\nsalones activos',
                          textAlign: TextAlign.center,
                          style: AppText.subtitle.copyWith(letterSpacing: 0.3),
                        ),
                      ),
                    )
                  else
                    for (final s in activos)
                      SalonAdminCard(
                        solicitud: s,
                        etiqueta: 'ACTIVO',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SolicitudSalonDetailScreen(solicitud: s),
                            ),
                          );
                        },
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
