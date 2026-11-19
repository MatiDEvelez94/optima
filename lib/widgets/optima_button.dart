import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'texto_sobre_fondo.dart';

class OptimaButton extends StatelessWidget {
  const OptimaButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.filled = true,
    this.width,
  });

  final String text;
  final VoidCallback onPressed;
  final bool filled;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final textColor = filled ? AppColors.cream : AppColors.navy;
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: filled ? AppColors.navy : const Color(0xFFCFD8E3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: filled
                ? BorderSide.none
                : const BorderSide(color: Color(0xFF0B57D0), width: 2),
          ),
        ),
        child: Text(text,
            style: GoogleFonts.lato(fontSize: 14, color: textColor)),
      ),
    );
  }
}

class OptimaLink extends StatelessWidget {
  const OptimaLink({super.key, required this.text, required this.onPressed});
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Negro sobre el crema; crema cuando queda sobre la parte azul del fondo
    return TextButton(
      onPressed: onPressed,
      child: TextoSobreFondo(
        oscuro: Colors.black,
        builder: (context, color) => Text(
          text,
          style: AppText.link.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}