import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

// Cuadro con lo que falta corregir en un formulario.
// Tiene fondo claro para que se lea aunque este sobre la parte oscura.
class CuadroErrores extends StatelessWidget {
  const CuadroErrores({super.key, required this.errores});

  final List<String> errores;

  @override
  Widget build(BuildContext context) {
    if (errores.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in errores)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '- $e',
                style: AppText.input.copyWith(
                  color: Colors.red.shade800,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}