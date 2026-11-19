import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/solicitud_salon.dart';
import '../repositories/api_client.dart';
import '../repositories/cuenta_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/carrusel_fotos.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';

// Todos los datos de una solicitud de salon, para que el administrador
// la verifique y la apruebe o la rechace.
class SolicitudSalonDetailScreen extends StatelessWidget {
  const SolicitudSalonDetailScreen({super.key, required this.solicitud});

  final SolicitudSalon solicitud;

  Future<void> _decidir(BuildContext context, EstadoSalon estado) async {
    try {
      // Se guarda en la base de datos
      await CuentaRepository.resolver(solicitud, estado);
    } on ApiError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.mensaje)),
      );
      return;
    }
    if (!context.mounted) return;
    Navigator.pop(
      context,
      estado == EstadoSalon.aprobada ? 'aprobado' : 'rechazado',
    );
  }

  // Abre la direccion en Google Maps para comprobar que existe
  Future<void> _abrirMaps() async {
    final url = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': solicitud.direccion,
    });
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final pendiente = s.estado == EstadoSalon.pendiente;

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OptimaBackButton(),
                    Center(
                      child: Text('Solicitud de salón', style: AppText.title),
                    ),
                    const Divider(
                      color: Colors.black87,
                      indent: 20,
                      endIndent: 20,
                    ),
                    const SizedBox(height: 16),
                    // Todas las fotos del salon, arriba
                    if (s.fotos.isEmpty)
                      Text(
                        'No cargó fotos',
                        style: AppText.input.copyWith(color: AppColors.navy),
                      )
                    else
                      CarruselFotos(
                        fotos: s.fotos
                            .map<ImageProvider>((f) => MemoryImage(f))
                            .toList(),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Datos del dueño',
                      style: AppText.title.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Nombre y apellido', value: s.nombreCompleto),
                    _DetailRow(label: 'Correo electrónico', value: s.correo),
                    _DetailRow(label: 'Teléfono', value: s.telefono),
                    _DetailRow(label: 'DNI', value: s.dni),
                    const SizedBox(height: 8),
                    Text(
                      'Datos del salón',
                      style: AppText.title.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Nombre del salón', value: s.salonNombre),
                    _DetailRow(label: 'Dirección', value: s.direccion),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OptimaButton(
                        text: 'Ver en Google Maps',
                        filled: false,
                        onPressed: _abrirMaps,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(label: 'Capacidad', value: '${s.capacidad} personas'),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Barra de abajo: decision del administrador
            Container(
              width: double.infinity,
              color: AppColors.navyLight,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: pendiente
                  ? Row(
                      children: [
                        Expanded(
                          child: OptimaButton(
                            text: 'Rechazar',
                            filled: false,
                            width: double.infinity,
                            onPressed: () =>
                                _decidir(context, EstadoSalon.rechazada),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OptimaButton(
                            text: 'Aprobar',
                            filled: false,
                            width: double.infinity,
                            onPressed: () =>
                                _decidir(context, EstadoSalon.aprobada),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          s.estado == EstadoSalon.aprobada
                              ? 'Salón aprobado'
                              : 'Solicitud rechazada',
                          style: AppText.banner.copyWith(fontSize: 20),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label),
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
              value.isEmpty ? '-' : value,
              style: AppText.input.copyWith(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}