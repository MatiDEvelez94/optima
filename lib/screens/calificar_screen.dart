import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../repositories/api_client.dart';
import '../repositories/evento_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';

// Ultimo paso para terminar un evento: el dueño califica a cada persona que
// trabajo. Las estrellas pasan a formar parte de la calificacion de la persona
// y el evento queda guardado en el historial.
// Vuelve con true si el evento se finalizo.
class CalificarScreen extends StatefulWidget {
  const CalificarScreen({super.key, required this.evento});

  final Evento evento;

  @override
  State<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends State<CalificarScreen> {
  // Estrellas elegidas para cada persona (0 = sin calificar)
  late final List<double> _estrellas =
      List<double>.filled(widget.evento.confirmados.length, 0);

  // Reseña opcional para cada persona
  late final List<TextEditingController> _resenias = List.generate(
    widget.evento.confirmados.length,
    (_) => TextEditingController(),
  );

  @override
  void dispose() {
    for (final c in _resenias) {
      c.dispose();
    }
    super.dispose();
  }

  bool _guardando = false;

  Future<void> _finalizar() async {
    if (_guardando) return;
    final ev = widget.evento;

    // Una reseña por cada persona confirmada, en el mismo orden
    final resenias = <Map<String, dynamic>>[
      for (var i = 0; i < ev.confirmados.length; i++)
        {
          'estrellas': _estrellas[i],
          'comentario': _resenias[i].text.trim(),
        },
    ];

    setState(() => _guardando = true);
    try {
      // El servidor termina el evento y guarda las calificaciones
      await EventoRepository.finalizarEvento(ev, resenias);
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  // Cinco estrellas: tocar la mitad izquierda de una estrella pone media
  // estrella (3,5 / 4,5...) y la mitad derecha pone la estrella entera.
  // Tocar el mismo valor otra vez saca la calificacion.
  Widget _estrellasDe(int i) {
    const tam = 34.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var n = 1; n <= 5; n++)
          GestureDetector(
            onTapDown: (d) {
              final valor = d.localPosition.dx < tam / 2 ? n - 0.5 : n * 1.0;
              setState(() => _estrellas[i] = _estrellas[i] == valor ? 0 : valor);
            },
            child: SizedBox(
              width: tam,
              height: tam,
              child: Icon(
                _estrellas[i] >= n
                    ? Icons.star
                    : (_estrellas[i] == n - 0.5
                        ? Icons.star_half
                        : Icons.star_border),
                size: tam,
                color: AppColors.navy,
              ),
            ),
          ),
        const SizedBox(width: 10),
        Text(
          _estrellas[i] == 0 ? '-' : Evento.formatoEstrellas(_estrellas[i]),
          style: AppText.input.copyWith(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final confirmados = widget.evento.confirmados;

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OptimaBackButton(),
                    Center(child: Text('Finalizar evento', style: AppText.title)),
                    const Divider(color: Colors.black87),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.evento.tipo} - '
                      '${Evento.formatoFecha(widget.evento.fecha)}',
                      style: AppText.input.copyWith(color: AppColors.navy),
                    ),
                    const SizedBox(height: 12),
                    if (confirmados.isEmpty)
                      Text(
                        'No confirmaste a nadie para este evento, así que no '
                        'hay personas para calificar. Igual puedes finalizarlo '
                        'y va a quedar en tu historial.',
                        style: AppText.subtitle.copyWith(
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      )
                    else ...[
                      Text(
                        'Califica a cada persona que trabajó en tu evento. '
                        'Es opcional, pero ayuda a otros salones. Toca la mitad '
                        'izquierda de una estrella para dar media estrella.',
                        style: AppText.subtitle.copyWith(
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < confirmados.length; i++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.field,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.navy),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                confirmados[i].nombre,
                                style: AppText.input.copyWith(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                confirmados[i].profesion,
                                style: AppText.input,
                              ),
                              const SizedBox(height: 8),
                              _estrellasDe(i),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _resenias[i],
                                maxLines: 3,
                                minLines: 2,
                                maxLength: 200,
                                style: AppText.input
                                    .copyWith(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Reseña u opinión (opcional)',
                                  hintStyle: AppText.input,
                                  filled: true,
                                  fillColor: AppColors.cream,
                                  counterStyle:
                                      AppText.input.copyWith(fontSize: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: AppColors.navy),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide:
                                        const BorderSide(color: AppColors.navy),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.navy,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.navyLight,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: OptimaButton(
                  text: _guardando ? 'Guardando...' : 'Finalizar y guardar',
                  filled: false,
                  onPressed: _finalizar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}