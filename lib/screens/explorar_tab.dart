import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../models/user_session.dart';
import '../repositories/evento_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/event_card.dart';
import '../widgets/gradient_background.dart';
import 'salon_detail_screen.dart';

// Pestaña de la lupa (solo dueños de salon): tu salon y los eventos
// activos de otros salones, para ver como se publican y cuanto pagan.
// Los eventos vienen de la base de datos (el servidor deja afuera los tuyos).
class ExplorarTab extends StatelessWidget {
  const ExplorarTab({super.key});

  List<Widget> _eventos() {
    final tarjetas = <Widget>[];
    for (final e in EventoRepository.activos) {
      final ev = e.evento;
      tarjetas.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          color: const Color(0xFFE6E3DC),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 320,
              height: 220,
              child: EventCard(
                image: 'assets/images/salon.jpg',
                imageBytes: e.fotos.isNotEmpty ? e.fotos.first : null,
                // Todas las fotos del salon: en el detalle se ve el carrusel
                fotos: e.fotos.isEmpty
                    ? null
                    : e.fotos
                        .map<ImageProvider>((b) => MemoryImage(b))
                        .toList(),
                salon: e.salon,
                direccion: e.direccion,
                date: Evento.formatoFecha(ev.fecha),
                size: ev.invitados > 0 ? '${ev.invitados} personas' : '-',
                schedule: ev.horario,
                // Se muestran todos los puestos con su pago por hora
                needs: ev.puestos.map((p) => p.etiqueta).toList(),
                notas: ev.notas,
                eventoId: e.id,
                // Sin "puestos": el dueño solo mira, no se postula
              ),
            ),
          ),
        ),
      );
    }
    return tarjetas;
  }

  @override
  Widget build(BuildContext context) {
    final eventos = _eventos();

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Tu salón',
                  style: AppText.title.copyWith(fontSize: 24),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: _SalonCard(),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Eventos activos',
                  style: AppText.title.copyWith(fontSize: 24),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Así se ven los eventos de otros salones',
                  style: AppText.input.copyWith(color: AppColors.navy),
                ),
              ),
              const SizedBox(height: 12),
              if (eventos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Center(
                    child: Text(
                      'Todavía no hay eventos de otros salones',
                      textAlign: TextAlign.center,
                      style: AppText.input.copyWith(color: AppColors.navy),
                    ),
                  ),
                )
              else
                ...eventos,
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// Tarjeta con la foto y los datos del salon inscripto.
// Al tocarla se abre el detalle completo del salon.
class _SalonCard extends StatelessWidget {
  const _SalonCard();

  @override
  Widget build(BuildContext context) {
    final nombre =
        UserSession.salonNombre.isEmpty ? 'Mi salón' : UserSession.salonNombre;
    final direccion =
        UserSession.salonDireccion.isEmpty ? '-' : UserSession.salonDireccion;
    final capacidad = UserSession.salonCapacidad.isEmpty
        ? '-'
        : '${UserSession.salonCapacidad} personas';

    final Widget foto = UserSession.salonFotos.isNotEmpty
        ? Image.memory(UserSession.salonFotos.first, fit: BoxFit.cover)
        : Image.asset('assets/images/salon.jpg', fit: BoxFit.cover);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalonDetailScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              SizedBox(width: 110, height: double.infinity, child: foto),
              Expanded(
                child: Container(
                  color: AppColors.navy,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.eventText.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Dirección: $direccion',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.eventText.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capacidad: $capacidad',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.eventText.copyWith(fontSize: 11),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Más información',
                          style: AppText.eventText.copyWith(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}