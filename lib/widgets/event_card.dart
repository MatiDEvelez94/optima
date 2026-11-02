import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cuenta.dart';
import '../models/evento.dart';
import '../models/postulacion.dart';
import '../screens/event_detail_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.image,
    required this.date,
    required this.size,
    required this.schedule,
    required this.needs,
    this.salon,
    this.mostrarSalon = true,
    this.direccion,
    this.puestos,
    this.horas,
    this.galeria,
    this.inicio,
    this.fin,
    this.imageBytes,
    this.fotos,
    this.notas,
    this.destino,
  });

  final String image;
  final String date;
  final String size;
  final String schedule;
  final List<String> needs;
  final String? salon; // nombre del salon (opcional)
  final bool mostrarSalon; // false = el nombre solo se ve en el detalle
  final String? direccion; // donde es el evento (opcional, va al detalle)
  final List<Puesto>? puestos; // si viene, en el detalle se puede postular
  final double? horas; // duracion del evento (para calcular el pago)
  final List<String>? galeria; // fotos para el detalle (rutas de assets)
  final DateTime? inicio; // cuando empieza (para no superponer eventos)
  final DateTime? fin; // cuando termina
  final Uint8List? imageBytes; // foto subida por un salon real (si hay)
  final List<ImageProvider>? fotos; // todas las fotos de un salon real
  final String? notas; // vestimenta u observaciones (opcional)
  final Cuenta? destino; // dueño que recibe las postulaciones (salon real)

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(
              image: image,
              date: date,
              size: size,
              schedule: schedule,
              needs: needs,
              salon: salon,
              direccion: direccion,
              puestos: puestos,
              horas: horas,
              inicio: inicio,
              fin: fin,
              imageBytes: imageBytes,
              notas: notas,
              destino: destino,
              fotos: fotos ??
                  galeria
                      ?.map<ImageProvider>((ruta) => AssetImage(ruta))
                      .toList(),
            ),
          ),
        );
        // Al volver del detalle se actualizan las postulaciones enviadas
        Postulacion.notificar();
      },
      child: SizedBox(
        width: 320,
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: double.infinity,
              child: imageBytes != null
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : Image.asset(image, fit: BoxFit.cover),
            ),
            Expanded(
              child: Container(
                color: AppColors.navy,
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (salon != null && mostrarSalon)
                      Text(
                        salon!,
                        style: AppText.eventText.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(date, style: AppText.eventText),
                    Text('Dimensión: $size', style: AppText.eventText),
                    const SizedBox(height: 6),
                    Text(
                      'Horario: $schedule',
                      style: AppText.eventText.copyWith(color: AppColors.cream),
                    ),
                    const SizedBox(height: 6),
                    Text('Busca:', style: AppText.eventText),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: needs
                          .map(
                            (n) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.field,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                n,
                                style: AppText.eventText.copyWith(
                                  color: AppColors.navy,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          )
                          .toList(),
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
    );
  }
}
