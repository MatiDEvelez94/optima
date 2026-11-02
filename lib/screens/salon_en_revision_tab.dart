import 'package:flutter/material.dart';
import '../models/solicitud_salon.dart';
import '../models/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';

// Inicio de un dueño cuyo salon todavia no fue aprobado (o fue rechazado):
// no puede crear eventos hasta que el administrador lo apruebe.
class SalonEnRevisionTab extends StatelessWidget {
  const SalonEnRevisionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final enRevision =
        UserSession.solicitudSalon?.estado != EstadoSalon.rechazada;

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                enRevision ? Icons.hourglass_top : Icons.block,
                size: 64,
                color: AppColors.navy,
              ),
              const SizedBox(height: 16),
              Text(
                enRevision
                    ? 'Tu salón está\nen revisión'
                    : 'Tu solicitud fue\nrechazada',
                textAlign: TextAlign.center,
                style: AppText.title.copyWith(fontSize: 26),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                color: AppColors.navyLight,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text(
                  enRevision
                      ? 'El equipo de Óptima está verificando los datos de tu '
                          'salón. Cuando lo aprobemos vas a poder crear tu '
                          'evento.'
                      : 'No pudimos aprobar la solicitud de tu salón. '
                          'Comunicate con nosotros para más información.',
                  textAlign: TextAlign.center,
                  style: AppText.banner.copyWith(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
