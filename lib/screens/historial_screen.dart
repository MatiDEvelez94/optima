import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../models/evento_finalizado.dart';
import '../models/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';

// Eventos que el dueño del salon ya termino, con las calificaciones que dio
class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historial = UserSession.cuentaActual?.historial ?? <EventoFinalizado>[];

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OptimaBackButton(),
              Center(child: Text('Historial', style: AppText.title)),
              const Divider(color: Colors.black87),
              const SizedBox(height: 12),
              if (historial.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'Todavía no finalizaste\nningun evento',
                      textAlign: TextAlign.center,
                      style: AppText.subtitle.copyWith(letterSpacing: 0.3),
                    ),
                  ),
                )
              else
                for (final e in historial) _EventoHistorial(evento: e),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventoHistorial extends StatelessWidget {
  const _EventoHistorial({required this.evento});

  final EventoFinalizado evento;

  Widget _estrellas(double n) {
    if (n == 0) {
      return Text('Sin calificar', style: AppText.input.copyWith(fontSize: 11));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            n >= i
                ? Icons.star
                : (n == i - 0.5 ? Icons.star_half : Icons.star_border),
            size: 16,
            color: AppColors.navy,
          ),
        const SizedBox(width: 4),
        Text(
          Evento.formatoEstrellas(n),
          style: AppText.input.copyWith(color: Colors.black87, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  evento.tipo,
                  style: AppText.input.copyWith(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'FINALIZADO',
                  style: AppText.eventText.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(evento.fecha, style: AppText.input.copyWith(fontSize: 12)),
          Text(evento.horario, style: AppText.input.copyWith(fontSize: 12)),
          Text(
            'Costo del evento: ${Evento.formatoDinero(evento.costoTotal)}',
            style: AppText.input.copyWith(fontSize: 12),
          ),
          const Divider(color: AppColors.navy, height: 20),
          Text('Personas que trabajaron', style: AppText.label),
          const SizedBox(height: 6),
          if (evento.personas.isEmpty)
            Text('Nadie fue confirmado', style: AppText.input)
          else
            for (final p in evento.personas)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${p.nombre} - ${p.profesion}',
                        style: AppText.input.copyWith(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    _estrellas(p.estrellas),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
