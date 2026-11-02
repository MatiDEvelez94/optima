import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child, this.plano = false});
  final Widget child;
  // plano = true: fondo crema liso, sin degradado azul
  final bool plano;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: plano ? AppColors.cream : null,
        gradient: plano ? null : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cream, AppColors.cream, AppColors.navy],
          stops: [0, 0.5, 1],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}