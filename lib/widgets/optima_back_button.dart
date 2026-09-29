import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OptimaBackButton extends StatelessWidget {
  const OptimaBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: AppColors.navy),
      ),
    );
  }
}