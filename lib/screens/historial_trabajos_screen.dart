import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../models/evento_finalizado.dart';
import '../models/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';

// Historial de quien busca trabajo: los eventos en los que ya trabajo, con el
// salon, el pago y la nota que le dio el salon
class HistorialTrabajosScreen extends StatelessWidget {
  const HistorialTrabajosScreen({super.key, this.esPestana = false});

  // true = va dentro de la barra de abajo (sin flecha de volver)
  final bool esPestana;

  @override
  Widget build(BuildContext context) {
    final trabajos =
        UserSession.cuentaActual?.historialTrabajos ?? <TrabajoRealizado>[];

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (esPestana) const SizedBox(height: 24) else const OptimaBackButton(),
              Center(child: Text('Mi historial', style: AppText.title)),
              const Divider(color: Colors.black87),
              const SizedBox(height: 12),
              if (trabajos.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      'Todavía no terminaste\nningún evento',
                      textAlign: TextAlign.center,
                      style: AppText.subtitle.copyWith(letterSpacing: 0.3),
                    ),
                  ),
                )
              else
                for (final t in trabajos) _TrabajoCard(trabajo: t),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrabajoCard extends StatefulWidget {
  const _TrabajoCard({required this.trabajo});

  final TrabajoRealizado trabajo;

  @override
  State<_TrabajoCard> createState() => _TrabajoCardState();
}

class _TrabajoCardState extends State<_TrabajoCard> {
  bool _detalles = false;

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
            size: 18,
            color: AppColors.navy,
          ),
        const SizedBox(width: 4),
        Text(
          Evento.formatoEstrellas(n),
          style: AppText.input.copyWith(color: Colors.black87, fontSize: 13),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trabajo;
    final estilo = AppText.input.copyWith(fontSize: 12);

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
                  t.salon,
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
                  'TERMINADO',
                  style: AppText.eventText.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${t.tipo} - ${t.fecha}', style: estilo),
          const Divider(color: AppColors.navy, height: 20),
          Text('Trabajaste de ${t.puesto}', style: estilo),
          Text(
            'Pago del evento: ${Evento.formatoDinero(t.pagoTotal)}',
            style: estilo.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Calificación del salón', style: AppText.label),
          const SizedBox(height: 4),
          _estrellas(t.estrellas),

          // Detalles (se abren con el botón de abajo a la derecha)
          if (_detalles) ...[
            const Divider(color: AppColors.navy, height: 20),
            Text(t.horario, style: estilo),
            if (t.direccion.isNotEmpty) Text(t.direccion, style: estilo),
            Text(
              '${Evento.formatoDinero(t.pagoHora)} por hora - '
              '${Evento.formatoHoras(t.horas)}',
              style: estilo,
            ),
            if (t.comentario.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Reseña del salón', style: AppText.label),
              const SizedBox(height: 4),
              Text(
                t.comentario,
                style: AppText.input.copyWith(
                  color: Colors.black87,
                  fontSize: 12,
                ),
              ),
            ],
          ],
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => setState(() => _detalles = !_detalles),
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _detalles ? Icons.remove : Icons.add,
                      size: 14,
                      color: AppColors.cream,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _detalles ? 'Menos detalles' : 'Más detalles',
                      style: AppText.eventText.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
