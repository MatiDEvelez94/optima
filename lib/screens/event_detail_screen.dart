import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/evento.dart';
import '../models/postulacion.dart';
import '../models/user_session.dart';
import '../repositories/api_client.dart';
import '../repositories/evento_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/carrusel_fotos.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';
import 'role_screen.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.image,
    required this.date,
    required this.size,
    required this.schedule,
    required this.needs,
    this.salon,
    this.fotos,
    this.imageBytes,
    this.notas,
    this.direccion,
    this.miPuesto,
    this.puestos,
    this.horas,
    this.inicio,
    this.fin,
    this.eventoId,
  });

  final String image; // foto de respaldo (ruta de assets)
  final String date;
  final String size;
  final String schedule;
  final List<String> needs;
  final String? salon; // nombre del salon (opcional)
  final List<ImageProvider>? fotos; // todas las fotos (si no, se usa image)
  final Uint8List? imageBytes; // una sola foto subida (si no viene fotos)
  final String? notas; // vestimenta u observaciones (opcional)
  final String? direccion; // donde es el evento (opcional)
  final String? miPuesto; // puesto asignado a la persona (opcional)
  final List<Puesto>? puestos; // si viene, se puede elegir un puesto y postular
  final double? horas; // duracion del evento (para calcular el pago)
  final DateTime? inicio; // cuando empieza (para no superponer eventos)
  final DateTime? fin; // cuando termina
  final String? eventoId; // id del evento en la base de datos

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _scroll = ScrollController();
  Puesto? _elegido;
  bool _enviando = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ---------- postulacion ----------

  String get _salonKey => widget.salon ?? 'Salón';

  // Ya se postulo a este puesto de este salon
  bool _yaPostulado(Puesto p) => Postulacion.enviadas
      .any((x) => x.salon == _salonKey && x.puesto == p.profesion);

  // Motivo por el que no puede postularse (o null si puede)
  String? get _motivoBloqueo => Postulacion.motivoBloqueo(
        salon: _salonKey,
        inicio: widget.inicio,
        fin: widget.fin,
      );

  // Elige (o des-elige) un puesto y baja para mostrar el panel
  void _elegir(Puesto p) {
    setState(() => _elegido = _elegido == p ? null : p);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_elegido != null && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarPostulacion(Puesto p) async {
    if (_enviando) return;
    final mensajes = ScaffoldMessenger.of(context);
    final motivo = _motivoBloqueo;
    if (motivo != null) {
      mensajes.showSnackBar(SnackBar(content: Text(motivo)));
      setState(() {});
      return;
    }
    final id = widget.eventoId;
    if (id == null) {
      mensajes.showSnackBar(
        const SnackBar(content: Text('Este evento no recibe postulaciones')),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      // Se guarda en la base de datos (el servidor vuelve a revisar las reglas)
      await EventoRepository.postular(eventoId: id, puesto: p.profesion);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mensajes.showSnackBar(SnackBar(content: Text(e.mensaje)));
      return;
    }
    if (!mounted) return;
    setState(() => _enviando = false);
    mensajes.showSnackBar(
      SnackBar(content: Text('Postulación enviada para ${p.profesion}')),
    );
  }

  // ---------- partes de la pantalla ----------

  Widget _dato(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.input.copyWith(color: AppColors.navy),
            ),
          ),
          Text(
            valor,
            style: AppText.input.copyWith(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Aviso cuando no se puede postular (un puesto por salon / horario ocupado)
  Widget _buildBloqueo(String motivo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.block, color: Colors.red.shade800, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            motivo,
            style: AppText.input.copyWith(
              color: Colors.red.shade800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Boton de abajo del panel: depende de si hay cuenta y de las reglas
  Widget _buildAccion(Puesto p) {
    if (!UserSession.logueado) {
      return OptimaButton(
        text: 'Crea una cuenta para postularte',
        width: double.infinity,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoleScreen()),
          );
        },
      );
    }
    if (_yaPostulado(p)) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.navy),
          const SizedBox(width: 8),
          Text(
            'Postulación enviada',
            style: AppText.input.copyWith(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    final motivo = _motivoBloqueo;
    if (motivo != null) return _buildBloqueo(motivo);

    return OptimaButton(
      text: _enviando ? 'Enviando...' : 'Enviar postulación',
      width: double.infinity,
      onPressed: () => _enviarPostulacion(p),
    );
  }

  // Panel con el pago y el boton para postularse al puesto elegido
  Widget _buildPanel(Puesto p) {
    final horas = widget.horas;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.profesion, style: AppText.title.copyWith(fontSize: 24)),
          const SizedBox(height: 10),
          _dato('Pago por hora', Evento.formatoDinero(p.pagoHora)),
          if (horas != null) _dato('Duración', Evento.formatoHoras(horas)),
          _dato('Vacantes', '${p.cantidad}'),
          if (horas != null) ...[
            const Divider(color: AppColors.navy),
            Text(
              'Pago estimado por el evento',
              style: AppText.input.copyWith(color: AppColors.navy),
            ),
            const SizedBox(height: 4),
            Text(
              Evento.formatoDinero(p.pagoHora * horas),
              style: AppText.input.copyWith(
                color: AppColors.navy,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildAccion(p),
        ],
      ),
    );
  }

  // Puestos que se pueden tocar para elegir uno
  Widget _buildPuestosElegibles(List<Puesto> puestos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TextoSobreFondo(
          scroll: _scroll,
          builder: (color) => Text(
            'Toca un puesto para ver el pago y postularte',
            style: AppText.input.copyWith(color: color, fontSize: 11),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in puestos)
              GestureDetector(
                onTap: () => _elegir(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _elegido == p ? AppColors.navy : AppColors.field,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.navy),
                  ),
                  child: Text(
                    '${p.profesion} (${p.cantidad})',
                    style: AppText.input.copyWith(
                      color: _elegido == p ? AppColors.cream : AppColors.navy,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_elegido != null) _buildPanel(_elegido!),
      ],
    );
  }

  // Puestos solo para mirar (sin postulacion)
  Widget _buildPuestosSimples() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.needs
          .map(
            (n) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.field,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.navy),
              ),
              child: Text(
                n,
                style: AppText.input.copyWith(color: AppColors.navy),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Todas las fotos van arriba, en el carrusel
    final List<ImageProvider> fotos = widget.fotos ??
        [
          widget.imageBytes != null
              ? MemoryImage(widget.imageBytes!)
              : AssetImage(widget.image),
        ];
    final puestos = widget.puestos;

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OptimaBackButton(),
              Center(child: Text('Detalle del evento', style: AppText.title)),
              const Divider(color: Colors.black87, indent: 20, endIndent: 20),
              const SizedBox(height: 20),
              CarruselFotos(fotos: fotos),
              const SizedBox(height: 24),
              if (widget.salon != null)
                _DetailRow(scroll: _scroll, label: 'Salón', value: widget.salon!),
              if (widget.direccion != null)
                _DetailRow(scroll: _scroll, label: 'Dirección', value: widget.direccion!),
              _DetailRow(scroll: _scroll, label: 'Fecha', value: widget.date),
              _DetailRow(scroll: _scroll, label: 'Dimensión', value: widget.size),
              _DetailRow(scroll: _scroll, label: 'Horario', value: widget.schedule),
              if (widget.notas != null && widget.notas!.isNotEmpty)
                _DetailRow(scroll: _scroll, label: 'Observaciones', value: widget.notas!),
              if (widget.miPuesto != null)
                _DetailRow(scroll: _scroll, label: 'Tu puesto', value: widget.miPuesto!),
              // "Busca" se muestra siempre, menos en el evento donde la persona
              // ya fue aceptada (ahi solo importan sus datos: puesto y pago)
              if (widget.miPuesto == null) ...[
                _TextoSobreFondo(
                  scroll: _scroll,
                  builder: (color) => Text(
                    'Busca',
                    style: AppText.label.copyWith(color: color),
                  ),
                ),
                const SizedBox(height: 8),
                if (puestos != null)
                  _buildPuestosElegibles(puestos)
                else
                  _buildPuestosSimples(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.scroll,
    required this.label,
    required this.value,
  });

  final ScrollController scroll;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TextoSobreFondo(
            scroll: scroll,
            builder: (color) =>
                Text(label, style: AppText.label.copyWith(color: color)),
          ),
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

// Un texto que cambia de color segun lo que tiene detras: el fondo de la
// pantalla va de crema (arriba) a azul (abajo), asi que el texto es azul sobre
// el crema y crema sobre el azul. Se actualiza solo al hacer scroll o cuando
// la pantalla cambia (por ejemplo al tocar un puesto).
class _TextoSobreFondo extends StatefulWidget {
  const _TextoSobreFondo({required this.scroll, required this.builder});

  final ScrollController scroll;
  final Widget Function(Color color) builder;

  @override
  State<_TextoSobreFondo> createState() => _TextoSobreFondoState();
}

class _TextoSobreFondoState extends State<_TextoSobreFondo> {
  Color _color = AppColors.navy;

  @override
  void initState() {
    super.initState();
    widget.scroll.addListener(_medir);
  }

  @override
  void dispose() {
    widget.scroll.removeListener(_medir);
    super.dispose();
  }

  void _medir() {
    if (!mounted) return;
    final caja = context.findRenderObject();
    if (caja is! RenderBox || !caja.attached || !caja.hasSize) return;
    final y = caja.localToGlobal(Offset.zero).dy + caja.size.height / 2;
    final alto = MediaQuery.of(context).size.height;
    // Pasada esta altura el fondo ya es lo bastante azul
    final nuevo = y / alto > 0.68 ? AppColors.cream : AppColors.navy;
    if (nuevo != _color) setState(() => _color = nuevo);
  }

  @override
  Widget build(BuildContext context) {
    // Despues de dibujar se vuelve a medir (el contenido pudo moverse)
    WidgetsBinding.instance.addPostFrameCallback((_) => _medir());
    return widget.builder(_color);
  }
}