import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../models/postulacion.dart';
import '../repositories/api_client.dart';
import '../repositories/evento_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// Seccion del inicio de quien busca trabajo: las postulaciones que envio y
// estan esperando respuesta. Si no envio ninguna, no se muestra nada.
class PostulacionesEnviadas extends StatelessWidget {
  const PostulacionesEnviadas({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Postulacion.cambios,
      builder: (context, _, _) {
        final enviadas = Postulacion.enviadas;
        if (enviadas.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Postulaciones enviadas',
              style: AppText.title.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              '${enviadas.length} esperando respuesta',
              style: AppText.input.copyWith(color: AppColors.navy),
            ),
            const SizedBox(height: 16),
            for (final p in enviadas) _PostulacionCard(postulacion: p),
          ],
        );
      },
    );
  }
}

class _PostulacionCard extends StatelessWidget {
  const _PostulacionCard({required this.postulacion});

  final Postulacion postulacion;

  // Pregunta y, si confirma, cancela la postulacion
  Future<void> _confirmarCancelar(BuildContext context) async {
    final p = postulacion;
    final confirmo = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar postulación'),
        content: Text(
          'Se va a cancelar tu postulación como ${p.puesto} en ${p.salon}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar postulación'),
          ),
        ],
      ),
    );
    if (confirmo != true) return;
    try {
      // Se borra de la base de datos
      await EventoRepository.cancelarPostulacion(p);
    } on ApiError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = postulacion;
    final estilo = AppText.input.copyWith(fontSize: 12);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.navy),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.puesto,
                    style: AppText.input.copyWith(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.salon,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: estilo,
                  ),
                  Text('${p.fecha} - ${p.horario}', style: estilo),
                  Text(
                    '${Evento.formatoDinero(p.pagoHora)} por hora',
                    style: estilo,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'PENDIENTE',
                    style: AppText.eventText.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _confirmarCancelar(context),
                  child: Text(
                    'Cancelar',
                    style: AppText.input.copyWith(
                      color: AppColors.navy,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}