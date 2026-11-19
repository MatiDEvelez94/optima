import 'package:flutter/material.dart';
import '../models/cuenta.dart';
import '../models/evento.dart';
import '../models/evento_aceptado.dart';
import '../models/user_session.dart';
import '../repositories/api_client.dart';
import '../repositories/evento_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/event_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_button.dart';
import '../models/evento_finalizado.dart';
import 'event_detail_screen.dart';
import 'login_screen.dart';
import 'postulaciones_enviadas.dart';
import 'role_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  // Eventos activos que vienen de la base de datos (de salones aprobados)
  List<Widget> _eventos() {
    final tarjetas = <Widget>[];
    for (final e in EventoRepository.activos) {
      final ev = e.evento;
      tarjetas.add(
        EventCard(
          image: 'assets/images/salon.jpg',
          imageBytes: e.fotos.isNotEmpty ? e.fotos.first : null,
          fotos: e.fotos.isEmpty
              ? null
              : e.fotos.map<ImageProvider>((b) => MemoryImage(b)).toList(),
          salon: e.salon,
          mostrarSalon: false,
          direccion: e.direccion,
          date: Evento.formatoFecha(ev.fecha),
          size: ev.invitados > 0 ? '${ev.invitados} personas' : '-',
          schedule: ev.horario,
          inicio: ev.inicioDT,
          fin: ev.finDT,
          horas: ev.horas,
          // Solo se muestran los lugares que todavia quedan libres
          needs: ev.completo
              ? ['Equipo completo']
              : ev.puestosAbiertos
                  .map((p) => '${p.profesion} (${p.cantidad})')
                  .toList(),
          puestos: ev.puestosAbiertos,
          notas: ev.notas,
          eventoId: e.id,
        ),
      );
    }
    return tarjetas;
  }

  @override
  Widget build(BuildContext context) {
    final aceptados = EventoAceptado.aceptados;

    // Eventos activos (vienen de la base de datos)
    final eventos = _eventos();

    final eventosActivos = <Widget>[
      const SizedBox(height: 24),
      Text(
        'Eventos activos',
        style: AppText.title.copyWith(fontSize: 24),
      ),
      const SizedBox(height: 12),
      if (eventos.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Text(
            'Por ahora no hay eventos activos',
            textAlign: TextAlign.center,
            style: AppText.input.copyWith(color: AppColors.navy),
          ),
        ),
      for (final e in eventos) _FilaEvento(tarjeta: e),
    ];

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (UserSession.logueado) ...[
                // Primero lo mio: avisos y eventos en los que me aceptaron.
                // Sin const a proposito: asi los avisos nuevos que llegan del
                // servidor se dibujan en cuanto se actualiza la pantalla
                _AvisosMozo(),
                const SizedBox(height: 24),
                Text(
                  'Mis eventos',
                  style: AppText.title.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  'Eventos en los que fuiste aceptado',
                  style: AppText.input.copyWith(color: AppColors.navy),
                ),
                const SizedBox(height: 16),
                if (aceptados.isEmpty)
                  const _SinAceptar()
                else
                  for (final e in aceptados) _EventoAceptadoCard(evento: e),
                const PostulacionesEnviadas(),
                ...eventosActivos,
                const SizedBox(height: 12),
              ] else ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        '¿Quieres participar?',
                        textAlign: TextAlign.center,
                        style: AppText.title.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Crea tu cuenta para inscribir tu salón o buscar trabajo',
                        textAlign: TextAlign.center,
                        style: AppText.subtitle,
                      ),
                      const SizedBox(height: 24),
                      OptimaButton(
                        text: 'Crea una cuenta',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RoleScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      OptimaLink(
                        text: 'Ya tengo cuenta',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                ...eventosActivos,
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Un evento activo dentro de la lista vertical (igual que en la pestaña del salon)
class _FilaEvento extends StatelessWidget {
  const _FilaEvento({required this.tarjeta});

  final Widget tarjeta;

  @override
  Widget build(BuildContext context) {
    // Sin fondo propio: se ve el mismo fondo crema de toda la pantalla
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(width: 320, height: 230, child: tarjeta),
      ),
    );
  }
}

// Mensajes para quien busca trabajo: solicitud rechazada o evento cancelado.
// Se quedan en el inicio hasta que toca "Entendido".
class _AvisosMozo extends StatefulWidget {
  const _AvisosMozo();

  @override
  State<_AvisosMozo> createState() => _AvisosMozoState();
}

class _AvisosMozoState extends State<_AvisosMozo> {
  // Borra el aviso de la base de datos y de la pantalla
  Future<void> _entendido(Cuenta cuenta, AvisoMozo a) async {
    try {
      await EventoRepository.quitarAviso(a);
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
      return;
    }
    if (!mounted) return;
    setState(() => cuenta.avisos.remove(a));
  }

  @override
  Widget build(BuildContext context) {
    final cuenta = UserSession.cuentaActual;
    if (cuenta == null || cuenta.avisos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          for (final a in List<AvisoMozo>.of(cuenta.avisos))
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade800, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.red.shade800),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          a.titulo,
                          style: AppText.input.copyWith(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(a.detalle, style: AppText.input.copyWith(fontSize: 12)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OptimaButton(
                      text: 'Entendido',
                      onPressed: () => _entendido(cuenta, a),
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

// Mensaje cuando todavia no hay ningun evento aceptado
class _SinAceptar extends StatelessWidget {
  const _SinAceptar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            'Aún no fuiste aceptado\nen ningún evento',
            textAlign: TextAlign.center,
            style: AppText.subtitle.copyWith(letterSpacing: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Cuando un salón acepte tu solicitud, vas a ver acá el evento, '
            'el puesto asignado y todos los detalles.',
            textAlign: TextAlign.center,
            style: AppText.input.copyWith(color: AppColors.navy, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// Evento aceptado: donde ir, de que trabajar y cuanto se paga
class _EventoAceptadoCard extends StatelessWidget {
  const _EventoAceptadoCard({required this.evento});

  final EventoAceptado evento;

  void _abrirDetalle(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          image: evento.image,
          imageBytes: evento.imageBytes,
          salon: evento.salon,
          direccion: evento.direccion,
          date: evento.fecha,
          size: evento.size,
          schedule: evento.horario,
          needs: evento.puestosEvento,
          miPuesto:
              '${evento.puesto} - ${Evento.formatoDinero(evento.pagoHora)}/h',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estilo = AppText.eventText.copyWith(fontSize: 11);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: GestureDetector(
        onTap: () => _abrirDetalle(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 100,
                  child: evento.imageBytes != null
                      ? Image.memory(evento.imageBytes!, fit: BoxFit.cover)
                      : Image.asset(evento.image, fit: BoxFit.cover),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.navy,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'CONFIRMADO',
                            style: AppText.eventText.copyWith(
                              color: AppColors.navy,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          evento.salon,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.eventText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('${evento.tipo} - ${evento.fecha}', style: estilo),
                        Text(evento.horario, style: estilo),
                        Text(
                          evento.direccion,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: estilo,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu puesto: ${evento.puesto}',
                          style: estilo.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${Evento.formatoDinero(evento.pagoHora)} por hora',
                          style: estilo,
                        ),
                        Text(
                          'Pago estimado: '
                          '${Evento.formatoDinero(evento.pagoEstimado)} '
                          '(${Evento.formatoHoras(evento.horas)})',
                          style: estilo,
                        ),
                        const SizedBox(height: 10),
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
      ),
    );
  }
}