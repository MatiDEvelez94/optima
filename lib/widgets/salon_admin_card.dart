import 'package:flutter/material.dart';
import '../models/solicitud_salon.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// Tarjeta de un salon para el administrador (solicitud o salon activo)
class SalonAdminCard extends StatelessWidget {
  const SalonAdminCard({
    super.key,
    required this.solicitud,
    required this.onTap,
    this.etiqueta,
  });

  final SolicitudSalon solicitud;
  final VoidCallback onTap;
  final String? etiqueta; // ej: ACTIVO

  @override
  Widget build(BuildContext context) {
    final Widget foto = solicitud.fotos.isNotEmpty
        ? Image.memory(solicitud.fotos.first, fit: BoxFit.cover)
        : Container(
            color: AppColors.cream,
            child: const Icon(Icons.storefront, color: AppColors.hint),
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.navy),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 64, height: 64, child: foto),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (etiqueta != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        etiqueta!,
                        style: AppText.eventText.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    solicitud.salonNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.input.copyWith(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Dueño: ${solicitud.nombreCompleto}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.input.copyWith(fontSize: 12),
                  ),
                  Text(
                    'Capacidad: ${solicitud.capacidad} - '
                    '${SolicitudSalon.formatoFecha(solicitud.fecha)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.input.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.navy),
          ],
        ),
      ),
    );
  }
}