import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../models/solicitud_salon.dart';
import '../models/user_session.dart';
import '../repositories/api_client.dart';
import '../repositories/cuenta_repository.dart';
import '../repositories/evento_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_button.dart';
import '../widgets/optima_text_field.dart';
import 'calificar_screen.dart';
import 'crear_evento_screen.dart';
import 'event_detail_screen.dart';
import 'historial_screen.dart';
import 'postulante_screen.dart';

// Inicio para quien inscribio un salon.
// Sin evento: solo el boton para crearlo.
// Con evento: el evento y las solicitudes recibidas.
class HomeTabSalon extends StatefulWidget {
  const HomeTabSalon({super.key});

  @override
  State<HomeTabSalon> createState() => _HomeTabSalonState();
}

class _HomeTabSalonState extends State<HomeTabSalon> {
  String _filtro = 'Todos';
  int _filtroKey = 0; // cambia para volver el filtro a "Todos"

  void _reiniciarFiltro() {
    _filtro = 'Todos';
    _filtroKey++;
  }

  Future<void> _crearEvento() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrearEventoScreen()),
    );
    if (!mounted) return;
    setState(_reiniciarFiltro); // refresca con el evento nuevo
  }

  Future<void> _editarEvento(Evento evento) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CrearEventoScreen(editar: evento)),
    );
    if (!mounted) return;
    setState(_reiniciarFiltro); // refresca con los datos nuevos
  }

  void _verHistorial() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistorialScreen()),
    );
  }

  // Pregunta y, si confirma, pasa a calificar a las personas y finalizar
  Future<void> _finalizar(Evento evento) async {
    final seguir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalizar evento'),
        content: const Text(
          'Vas a dar por terminado el evento. Después puedes calificar a las '
          'personas que trabajaron y el evento queda en tu historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (seguir != true || !mounted) return;

    final finalizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CalificarScreen(evento: evento)),
    );
    if (finalizado != true || !mounted) return;
    setState(_reiniciarFiltro);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento finalizado. Quedó en tu historial')),
    );
  }

  Future<void> _confirmarEliminar() async {
    final evento = Evento.activo;
    if (evento == null) return;
    final confirmo = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar evento'),
        content: Text(
          evento.confirmados.isNotEmpty
              ? 'Hay ${evento.confirmados.length} persona(s) '
                  'confirmada(s). Si eliminas el evento se las saca, se '
                  'borran las solicitudes y no se califica a nadie. Si el '
                  'evento ya se hizo, usa "Finalizar evento".'
              : 'Se va a borrar tu evento y las solicitudes recibidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmo != true || !mounted) return;
    try {
      // Se cancela en la base de datos y a las personas afectadas les llega un aviso
      await EventoRepository.eliminarEvento(evento);
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
      return;
    }
    if (!mounted) return;
    setState(_reiniciarFiltro);
  }

  // Abre el perfil de la persona; al volver, si el dueño decidio, se guarda
  // en la base de datos y la persona sale de la lista
  Future<void> _verPerfil(SolicitudRecibida s) async {
    final resultado = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PostulanteScreen(
          nombre: s.nombre,
          profesion: s.profesion,
          calificacion: s.calificacion,
          telefono: s.telefono,
          cuenta: s.cuenta,
        ),
      ),
    );
    if (resultado == null || !mounted) return;

    try {
      await EventoRepository.decidir(s, confirmar: resultado == 'confirmada');
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
      return;
    }
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Solicitud de ${s.nombre} $resultado')),
    );
  }

  // Cartel "salon aprobado": se ve hasta que el dueño toca "Entendido"
  bool get _mostrarAvisoAprobado {
    final s = UserSession.solicitudSalon;
    return s != null && s.estado == EstadoSalon.aprobada && !s.avisoVisto;
  }

  // Guarda en la base de datos que el dueño ya vio el cartel
  Future<void> _entendido() async {
    try {
      await CuentaRepository.marcarAvisoVisto();
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
      return;
    }
    if (!mounted) return;
    setState(() => UserSession.solicitudSalon?.avisoVisto = true);
  }

  Widget _avisoAprobado() {
    final nombre =
        UserSession.salonNombre.isEmpty ? 'Tu salón' : UserSession.salonNombre;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.navy, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: AppColors.navy, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.input.copyWith(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'APROBADO',
                  style: AppText.eventText.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tu salón está aprobado. Ya puedes crear eventos.',
            style: AppText.input.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OptimaButton(
              text: 'Entendido',
              onPressed: _entendido,
            ),
          ),
        ],
      ),
    );
  }

  // Todavia no hay evento: solo el boton para crearlo
  List<Widget> _sinEvento() {
    return [
      const SizedBox(height: 60),
      Center(
        child: Text(
          'Todavía no creaste\nningun evento',
          textAlign: TextAlign.center,
          style: AppText.subtitle.copyWith(letterSpacing: 0.3),
        ),
      ),
      const SizedBox(height: 28),
      OptimaButton(
        text: 'Crear evento',
        width: double.infinity,
        onPressed: _crearEvento,
      ),
      const SizedBox(height: 8),
      Center(
        child: OptimaLink(
          text: 'Historial de eventos',
          onPressed: _verHistorial,
        ),
      ),
    ];
  }

  // Ya hay evento: la tarjeta del evento y las solicitudes
  List<Widget> _conEvento(Evento evento) {
    final profesionesEvento = evento.puestos.map((p) => p.profesion).toList();

    // Solo se muestran solicitudes de los puestos que pidio el evento
    final delEvento = EventoRepository.recibidas.where(
      (s) => profesionesEvento.any(
        (p) => p.toLowerCase() == s.profesion.toLowerCase(),
      ),
    );
    final visibles = _filtro == 'Todos'
        ? delEvento.toList()
        : delEvento.where((s) => s.profesion == _filtro).toList();
    final opciones = {'Todos', ...profesionesEvento}.toList();

    return [
      Center(
        child: Text(
          'Tu evento',
          style: AppText.title.copyWith(fontSize: 24),
        ),
      ),
      const SizedBox(height: 8),
      _EventoCard(evento: evento),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OptimaLink(
            text: 'Editar evento',
            onPressed: () => _editarEvento(evento),
          ),
          OptimaLink(
            text: 'Eliminar evento',
            onPressed: _confirmarEliminar,
          ),
        ],
      ),
      OptimaButton(
        text: 'Finalizar evento',
        width: double.infinity,
        onPressed: () => _finalizar(evento),
      ),
      Center(
        child: OptimaLink(
          text: 'Historial de eventos',
          onPressed: _verHistorial,
        ),
      ),
      const SizedBox(height: 4),
      _Confirmados(evento: evento),
      Text(
        'Solicitudes recibidas',
        style: AppText.title.copyWith(fontSize: 22),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 170,
          child: OptimaDropdown<String>(
            key: ValueKey('filtro$_filtroKey'),
            hint: 'Profesión',
            items: opciones,
            onChanged: (v) => setState(() => _filtro = v ?? 'Todos'),
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (visibles.isEmpty)
        Center(
          child: Text(
            _filtro == 'Todos'
                ? 'Todavía no recibiste solicitudes'
                : 'No hay solicitudes para ese filtro',
            textAlign: TextAlign.center,
            style: AppText.subtitle.copyWith(fontSize: 15, letterSpacing: 0.3),
          ),
        )
      else
        for (final s in visibles)
          _SolicitudCard(solicitud: s, onVerPerfil: () => _verPerfil(s)),
      const SizedBox(height: 24),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final evento = Evento.activo;

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_mostrarAvisoAprobado) _avisoAprobado(),
              ...(evento == null ? _sinEvento() : _conEvento(evento)),
            ],
          ),
        ),
      ),
    );
  }
}

// Tarjeta del evento: foto del salon y datos del evento.
// Al tocarla se abre el detalle, igual que en los eventos de otros salones.
class _EventoCard extends StatelessWidget {
  const _EventoCard({required this.evento});

  final Evento evento;

  void _abrirDetalle(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          image: 'assets/images/salon.jpg',
          imageBytes: UserSession.salonFotos.isNotEmpty
              ? UserSession.salonFotos.first
              : null,
          fotos: UserSession.salonFotos.isNotEmpty
              ? UserSession.salonFotos
                  .map<ImageProvider>((b) => MemoryImage(b))
                  .toList()
              : null,
          salon: UserSession.salonNombre.isEmpty
              ? 'Mi salón'
              : UserSession.salonNombre,
          date: Evento.formatoFecha(evento.fecha),
          size: evento.invitados > 0 ? '${evento.invitados} personas' : '-',
          schedule: '${Evento.formatoHora(evento.inicio)}hs - '
              '${Evento.formatoHora(evento.fin)}hs',
          needs: evento.puestos.map(evento.etiquetaRestante).toList(),
          notas: evento.notas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget foto = UserSession.salonFotos.isNotEmpty
        ? Image.memory(UserSession.salonFotos.first, fit: BoxFit.cover)
        : Image.asset('assets/images/salon.jpg', fit: BoxFit.cover);

    final estilo = AppText.eventText.copyWith(fontSize: 11);

    return GestureDetector(
      onTap: () => _abrirDetalle(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 110, child: foto),
              Expanded(
                child: Container(
                  color: AppColors.navy,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        evento.tipo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.eventText.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(Evento.formatoFecha(evento.fecha), style: estilo),
                      Text(
                        '${Evento.formatoHora(evento.inicio)} a '
                        '${Evento.formatoHora(evento.fin)} '
                        '(${Evento.formatoHoras(evento.horas)})',
                        style: estilo,
                      ),
                      if (evento.invitados > 0)
                        Text('Invitados: ${evento.invitados}', style: estilo),
                      const SizedBox(height: 8),
                      Text('Busca:', style: estilo),
                      for (final p in evento.puestos)
                        Text('- ${evento.etiquetaRestante(p)}', style: estilo),
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
    );
  }
}

// Una solicitud: foto, nombre, profesion y calificacion de la persona
class _SolicitudCard extends StatelessWidget {
  const _SolicitudCard({required this.solicitud, required this.onVerPerfil});

  final SolicitudRecibida solicitud;
  final VoidCallback onVerPerfil;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.cream,
            backgroundImage: solicitud.cuenta?.foto != null
                ? MemoryImage(solicitud.cuenta!.foto!)
                : null,
            child: solicitud.cuenta?.foto == null
                ? const Icon(Icons.person, size: 28, color: AppColors.hint)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  solicitud.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.input.copyWith(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(solicitud.profesion, style: AppText.input),
              ],
            ),
          ),
          // Al tocar la calificacion se abre el perfil de la persona
          GestureDetector(
            onTap: onVerPerfil,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: AppColors.cream),
                  const SizedBox(width: 4),
                  Text(
                    solicitud.calificacion?.toStringAsFixed(1) ?? 'Nuevo',
                    style: AppText.eventText.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Lista de las personas ya confirmadas, con cuantos lugares quedan por puesto
class _Confirmados extends StatelessWidget {
  const _Confirmados({required this.evento});

  final Evento evento;

  @override
  Widget build(BuildContext context) {
    final total = evento.puestos.fold<int>(0, (suma, p) => suma + p.cantidad);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmados (${evento.confirmados.length} de $total)',
          style: AppText.title.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        if (evento.confirmados.isEmpty)
          Text(
            'Todavía no confirmaste a nadie',
            style: AppText.input.copyWith(color: AppColors.navy),
          )
        else
          for (final c in evento.confirmados)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 18, color: AppColors.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${c.nombre} - ${c.profesion}',
                      style: AppText.input.copyWith(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 18),
      ],
    );
  }
}