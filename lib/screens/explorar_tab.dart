import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/event_card.dart';
import '../widgets/gradient_background.dart';
import 'salon_detail_screen.dart';

// Evento de OTRO salon (datos de ejemplo hasta que haya base de datos)
class _EventoAjeno {
  const _EventoAjeno({
    required this.salon,
    required this.date,
    required this.size,
    required this.schedule,
    required this.needs,
  });

  final String salon;
  final String date;
  final String size;
  final String schedule;
  final List<String> needs;
}

// Pestaña de la lupa (solo dueños de salon): tu salon y los eventos
// activos de otros salones, para ver como se publican y cuanto pagan
class ExplorarTab extends StatelessWidget {
  const ExplorarTab({super.key});

  // Ejemplos inventados: los salones y los pagos no son reales
  static const _eventos = [
    _EventoAjeno(
      salon: 'Salón Los Pinos',
      date: 'Sábado 28/11',
      size: '250 personas',
      schedule: '17:30hs - 5:30hs',
      needs: [
        'Mozo x8 - \$5.200/h',
        'Bachero x3 - \$4.300/h',
        'Cocinero x2 - \$6.000/h',
        'Animación x1 - \$7.500/h',
        'Bartender x2 - \$5.800/h',
      ],
    ),
    _EventoAjeno(
      salon: 'Salón Aurora',
      date: 'Viernes 4/12',
      size: '120 personas',
      schedule: '20:00hs - 2:00hs',
      needs: [
        'Mozo x4 - \$4.800/h',
        'Cocinero x1 - \$5.800/h',
        'Decorador x1 - \$6.500/h',
      ],
    ),
    _EventoAjeno(
      salon: 'Quinta Los Álamos',
      date: 'Sábado 12/12',
      size: '300 personas',
      schedule: '19:00hs - 6:00hs',
      needs: [
        'Mozo x10 - \$5.500/h',
        'Bachero x4 - \$4.500/h',
        'Limpieza x2 - \$4.000/h',
        'Animación x1 - \$8.000/h',
        'Bartender x1 - \$5.500/h',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
              for (final e in _eventos)
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
                        salon: e.salon,
                        date: e.date,
                        size: e.size,
                        schedule: e.schedule,
                        needs: e.needs,
                      ),
                    ),
                  ),
                ),
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
