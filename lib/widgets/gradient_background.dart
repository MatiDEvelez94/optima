import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'texto_sobre_fondo.dart';

class GradientBackground extends StatefulWidget {
  const GradientBackground({super.key, required this.child, this.plano = false});
  final Widget child;
  // plano = true: fondo crema liso, sin degradado azul
  final bool plano;

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground> {
  // Sirve para que los textos sepan donde esta el fondo y cambien de color
  final GlobalKey _claveFondo = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final plano = widget.plano;
    return FondoInfo(
      clave: _claveFondo,
      degradado: !plano,
      child: Container(
        key: _claveFondo,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: plano ? AppColors.cream : null,
          gradient: plano
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.cream, AppColors.cream, AppColors.navy],
                  stops: [0, 0.5, 1],
                ),
        ),
        child: SafeArea(child: widget.child),
      ),
    );
  }
}