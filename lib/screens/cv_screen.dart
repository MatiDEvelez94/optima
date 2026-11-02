import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/cuenta.dart';
import '../models/whatsapp.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/optima_back_button.dart';
import '../widgets/optima_button.dart';

// Curriculum de una persona que mando solicitud.
//  - Si es una persona real (tiene cuenta): se muestra el PDF que subio al
//    registrarse. Si no subio ninguno, se avisa.
//  - Si es una persona de EJEMPLO: se muestra un curriculum de mentira.
class CvScreen extends StatelessWidget {
  const CvScreen({
    super.key,
    required this.nombre,
    required this.profesion,
    this.telefono,
    this.cuenta,
  });

  final String nombre;
  final String profesion;
  final String? telefono; // el que cargo al registrarse (si no, el de prueba)
  final Cuenta? cuenta; // null = persona de ejemplo

  // Abre WhatsApp directo con el telefono de la persona
  void _contactar(BuildContext context) {
    Whatsapp.abrir(
      context,
      telefono: telefono ?? Whatsapp.telefonoDePrueba,
      mensaje: Whatsapp.mensajeParaPostulante(
        nombre: nombre,
        profesion: profesion,
      ),
    );
  }

  Widget _seccion(String titulo, List<String> lineas) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppText.label.copyWith(fontSize: 16)),
          const Divider(color: AppColors.navy, height: 12),
          for (final l in lineas)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l,
                style: AppText.input.copyWith(color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }

  // El PDF real que subio la persona
  Widget _pdfReal(Cuenta c) {
    return SfPdfViewer.memory(c.cvBytes!);
  }

  // La persona tiene cuenta pero no subio curriculum
  Widget _sinCv() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined,
                size: 56, color: AppColors.hint),
            const SizedBox(height: 12),
            Text(
              'Esta persona no cargó currículum',
              textAlign: TextAlign.center,
              style: AppText.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes contactarla para pedírselo.',
              textAlign: TextAlign.center,
              style: AppText.input.copyWith(color: AppColors.navy),
            ),
          ],
        ),
      ),
    );
  }

  // Curriculum de mentira para las personas de ejemplo
  Widget _cvEjemplo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nombre, style: AppText.title.copyWith(fontSize: 26)),
          Text(profesion, style: AppText.input.copyWith(fontSize: 14)),
          _seccion('Resumen', [
            'Persona con experiencia en eventos y buena '
                'predisposición para el trabajo en equipo.',
          ]),
          _seccion('Experiencia', [
            '- Salón de eventos (2 años)',
            '- Servicio de catering (1 año)',
          ]),
          _seccion('Formación', [
            '- Secundario completo',
            '- Curso de manipulación de alimentos',
          ]),
          _seccion('Disponibilidad', ['Fines de semana y feriados']),
          const SizedBox(height: 16),
          Text(
            '(Currículum de ejemplo)',
            style: AppText.input.copyWith(fontSize: 11, color: AppColors.hint),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = cuenta;
    final Widget contenido;
    if (c == null) {
      contenido = _cvEjemplo();
    } else if (c.cvBytes != null) {
      contenido = _pdfReal(c);
    } else {
      contenido = _sinCv();
    }

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: OptimaBackButton(),
            ),
            if (c != null && c.cvNombre.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  c.cvNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.input.copyWith(color: AppColors.navy),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.navy),
                  ),
                  child: contenido,
                ),
              ),
            ),
            // Barra de abajo con el boton para contactar
            Container(
              width: double.infinity,
              color: AppColors.navyLight,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: OptimaButton(
                  text: 'Contactarte',
                  filled: false,
                  onPressed: () => _contactar(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
